<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

class AdminController extends Controller
{
    public function metrics(): JsonResponse
    {
        $ordersByStatus = Order::query()
            ->select('status', DB::raw('count(*) as total'))
            ->groupBy('status')
            ->pluck('total', 'status');

        $revenue = (int) Order::where('payment_status', 'paid')->sum('total_cents');
        $paidOrders = (int) Order::where('payment_status', 'paid')->count();

        // Total discount handed out: the frozen regular price minus the price
        // actually billed, across every order line that carries a snapshot.
        $discount = (int) OrderItem::query()
            ->whereNotNull('compare_at_price_cents')
            ->whereColumn('compare_at_price_cents', '>', 'unit_price_cents')
            ->sum(DB::raw('(compare_at_price_cents - unit_price_cents) * quantity'));

        return response()->json([
            'data' => [
                'orders_by_status' => $ordersByStatus,
                'orders_total' => (int) $ordersByStatus->sum(),
                'awaiting_fulfilment' => (int) $ordersByStatus->only(['confirmed', 'packing', 'ready_for_delivery', 'out_for_delivery'])->sum(),
                'revenue_cents' => $revenue,
                'avg_order_cents' => $paidOrders ? intdiv($revenue, $paidOrders) : 0,
                'discount_cents' => $discount,
                'cod_orders' => (int) Order::where('payment_method', 'cod')->count(),
                'refunded_cents' => (int) Order::sum('refunded_amount_cents'),
                'customers' => User::where('is_admin', false)->count(),
                'products' => Product::count(),
                'low_stock' => Product::where('inventory_quantity', '<=', 5)->count(),
            ],
        ]);
    }

    /**
     * Orders bucketed over time for the dashboard charts. Grouping is done in
     * PHP so it works the same on SQLite (tests) and MySQL (runtime).
     */
    public function ordersTimeseries(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'bucket' => ['sometimes', 'in:day,week,month'],
            'from' => ['sometimes', 'date'],
            'to' => ['sometimes', 'date', 'after_or_equal:from'],
        ]);

        $bucket = $validated['bucket'] ?? 'day';
        $to = isset($validated['to']) ? Carbon::parse($validated['to'])->endOfDay() : now()->endOfDay();

        $span = ['day' => 13, 'week' => 11, 'month' => 11][$bucket];
        $from = isset($validated['from']) ? Carbon::parse($validated['from']) : match ($bucket) {
            'day' => $to->copy()->subDays($span),
            'week' => $to->copy()->subWeeks($span),
            'month' => $to->copy()->subMonths($span),
        };

        // Never build more than this many buckets (guards a huge custom range).
        $maxBuckets = ['day' => 186, 'week' => 130, 'month' => 60][$bucket];
        $earliest = match ($bucket) {
            'day' => $to->copy()->subDays($maxBuckets - 1),
            'week' => $to->copy()->subWeeks($maxBuckets - 1),
            'month' => $to->copy()->subMonths($maxBuckets - 1),
        };
        if ($from->lt($earliest)) {
            $from = $earliest;
        }

        $from = match ($bucket) {
            'day' => $from->copy()->startOfDay(),
            'week' => $from->copy()->startOfWeek(Carbon::MONDAY),
            'month' => $from->copy()->startOfMonth(),
        };

        $keyFor = fn (Carbon $d): string => match ($bucket) {
            'day' => $d->format('Y-m-d'),
            'week' => $d->copy()->startOfWeek(Carbon::MONDAY)->format('Y-m-d'),
            'month' => $d->format('Y-m-01'),
        };
        $labelFor = fn (Carbon $d): string => $bucket === 'month' ? $d->format('M Y') : $d->format('M j');

        $orders = Order::query()
            ->whereBetween('created_at', [$from, $to])
            ->get(['created_at', 'status', 'payment_status', 'payment_method', 'total_cents']);

        $agg = [];
        foreach ($orders as $order) {
            $key = $keyFor($order->created_at);
            $agg[$key] ??= ['orders' => 0, 'paid_orders' => 0, 'revenue_cents' => 0];
            $agg[$key]['orders']++;
            if ($order->payment_status === 'paid') {
                $agg[$key]['paid_orders']++;
                $agg[$key]['revenue_cents'] += (int) $order->total_cents;
            }
        }

        $series = [];
        $cursor = $from->copy();
        while ($cursor <= $to && count($series) < $maxBuckets) {
            $key = $keyFor($cursor);
            $series[] = [
                'period' => $key,
                'label' => $labelFor($cursor),
                'orders' => $agg[$key]['orders'] ?? 0,
                'paid_orders' => $agg[$key]['paid_orders'] ?? 0,
                'revenue_cents' => $agg[$key]['revenue_cents'] ?? 0,
            ];
            match ($bucket) {
                'day' => $cursor->addDay(),
                'week' => $cursor->addWeek(),
                'month' => $cursor->addMonth(),
            };
        }

        return response()->json([
            'data' => [
                'bucket' => $bucket,
                'from' => $from->toDateString(),
                'to' => $to->toDateString(),
                'series' => $series,
                'by_status' => $orders->countBy('status'),
                'by_payment_method' => $orders->countBy('payment_method'),
                'totals' => [
                    'orders' => array_sum(array_column($series, 'orders')),
                    'paid_orders' => array_sum(array_column($series, 'paid_orders')),
                    'revenue_cents' => array_sum(array_column($series, 'revenue_cents')),
                ],
            ],
        ]);
    }

    /**
     * One period-over-period comparison for the dashboard. `preset` picks the
     * span (day / two_day / week / month / six_month / year) or `custom` with a
     * rolling `days` window. The current window runs to "now"; the previous
     * window is the FULL prior period (all of last month, not just its first N
     * days) so two whole months can be read side by side. Returns the two
     * window totals and a `partial` flag for the still-running current period.
     */
    public function ordersCompare(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'preset' => ['sometimes', 'in:day,two_day,week,month,six_month,year,custom'],
            'days' => ['required_if:preset,custom', 'integer', 'min:1', 'max:730'],
        ]);

        $preset = $validated['preset'] ?? 'month';
        $days = isset($validated['days']) ? (int) $validated['days'] : null;
        $now = now();

        [$curStart, $curFullEnd, $prevStart, $prevEnd, $unit, $curLabel, $prevLabel] = $this->comparePreset($preset, $days, $now);

        $curTotals = ['orders' => 0, 'paid_orders' => 0, 'revenue_cents' => 0];
        $prevTotals = $curTotals;

        Order::query()
            ->where('created_at', '>=', $prevStart)
            ->where('created_at', '<', $now)
            ->get(['created_at', 'payment_status', 'total_cents'])
            ->each(function (Order $order) use (
                &$curTotals, &$prevTotals, $curStart, $now, $prevStart, $prevEnd
            ): void {
                $moment = $order->created_at;
                $paid = $order->payment_status === 'paid';
                $revenue = $paid ? (int) $order->total_cents : 0;

                if ($moment >= $curStart && $moment < $now) {
                    $curTotals['orders']++;
                    $curTotals['paid_orders'] += $paid ? 1 : 0;
                    $curTotals['revenue_cents'] += $revenue;
                } elseif ($moment >= $prevStart && $moment < $prevEnd) {
                    $prevTotals['orders']++;
                    $prevTotals['paid_orders'] += $paid ? 1 : 0;
                    $prevTotals['revenue_cents'] += $revenue;
                }
            });

        return response()->json(['data' => [
            'preset' => $preset,
            'days' => $preset === 'custom' ? $days : null,
            'bucket' => $unit,
            'partial' => $now->lt($curFullEnd),
            'current' => ['label' => $curLabel, 'from' => $curStart->toIso8601String(), 'to' => $now->toIso8601String(), ...$curTotals],
            'previous' => ['label' => $prevLabel, 'from' => $prevStart->toIso8601String(), 'to' => $prevEnd->toIso8601String(), ...$prevTotals],
        ]]);
    }

    /**
     * An orders-by-weekday-and-hour grid for the last 90 days, for the
     * dashboard activity heatmap.
     */
    public function ordersInsights(): JsonResponse
    {
        $since = now()->subDays(90)->startOfDay();
        $matrix = array_fill(0, 7, array_fill(0, 24, 0));
        $peak = 0;

        Order::query()
            ->where('created_at', '>=', $since)
            ->get(['created_at'])
            ->each(function (Order $order) use (&$matrix, &$peak): void {
                $row = (int) $order->created_at->dayOfWeekIso - 1; // Mon=0 .. Sun=6
                $col = (int) $order->created_at->format('G');       // 0..23
                $matrix[$row][$col]++;
                $peak = max($peak, $matrix[$row][$col]);
            });

        return response()->json(['data' => [
            'activity' => [
                'rows' => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                'matrix' => $matrix,
                'peak' => $peak,
                'since' => $since->toDateString(),
            ],
        ]]);
    }

    /**
     * @return array{0: Carbon, 1: Carbon, 2: Carbon, 3: Carbon, 4: string, 5: string, 6: string}
     *         [currentStart, currentFullEnd, previousStart, previousEnd, bucketUnit, currentLabel, previousLabel]
     */
    private function comparePreset(string $preset, ?int $days, Carbon $now): array
    {
        return match ($preset) {
            'day' => [
                $now->copy()->startOfDay(), $now->copy()->startOfDay()->addDay(),
                $now->copy()->startOfDay()->subDay(), $now->copy()->startOfDay(),
                'hour', 'Today', 'Yesterday',
            ],
            'two_day' => [
                $now->copy()->subDays(2), $now->copy(),
                $now->copy()->subDays(4), $now->copy()->subDays(2),
                'hour', 'Last 2 days', 'Previous 2 days',
            ],
            'week' => [
                $now->copy()->startOfWeek(Carbon::MONDAY), $now->copy()->startOfWeek(Carbon::MONDAY)->addWeek(),
                $now->copy()->startOfWeek(Carbon::MONDAY)->subWeek(), $now->copy()->startOfWeek(Carbon::MONDAY),
                'day', 'This week', 'Last week',
            ],
            'month' => [
                $now->copy()->startOfMonth(), $now->copy()->startOfMonth()->addMonthNoOverflow(),
                $now->copy()->startOfMonth()->subMonthNoOverflow(), $now->copy()->startOfMonth(),
                'day', 'This month', 'Last month',
            ],
            'six_month' => [
                $now->copy()->startOfMonth()->subMonthsNoOverflow(5), $now->copy()->startOfMonth()->addMonthNoOverflow(),
                $now->copy()->startOfMonth()->subMonthsNoOverflow(11), $now->copy()->startOfMonth()->subMonthsNoOverflow(5),
                'month', 'Last 6 months', 'Previous 6 months',
            ],
            'year' => [
                $now->copy()->startOfYear(), $now->copy()->startOfYear()->addYear(),
                $now->copy()->startOfYear()->subYear(), $now->copy()->startOfYear(),
                'month', 'This year', 'Last year',
            ],
            'custom' => [
                $now->copy()->subDays($days), $now->copy(),
                $now->copy()->subDays($days * 2), $now->copy()->subDays($days),
                $days <= 2 ? 'hour' : ($days <= 92 ? 'day' : 'month'),
                "Last {$days} days",
                "Previous {$days} days",
            ],
        };
    }

    public function customers(): JsonResponse
    {
        $customers = User::query()
            ->where('is_admin', false)
            ->withCount('orders')
            ->withSum(['orders as spent_cents' => fn ($query) => $query->where('payment_status', 'paid')], 'total_cents')
            ->latest()
            ->paginate(25);

        return response()->json([
            'data' => $customers->through(fn (User $user) => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'is_rider' => (bool) $user->is_rider,
                'orders_count' => $user->orders_count,
                'spent_cents' => (int) ($user->spent_cents ?? 0),
                'joined_at' => $user->created_at,
            ])->items(),
            'meta' => [
                'current_page' => $customers->currentPage(),
                'last_page' => $customers->lastPage(),
                'total' => $customers->total(),
            ],
        ]);
    }

    public function customer(User $user): JsonResponse
    {
        if ($user->is_admin) {
            throw new NotFoundHttpException();
        }

        return response()->json([
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'is_rider' => (bool) $user->is_rider,
                'joined_at' => $user->created_at,
                'addresses' => $user->addresses()->latest()->get(),
                'orders' => $user->orders()->with('items')->latest()->get(),
            ],
        ]);
    }

    public function updateCustomer(Request $request, User $user): JsonResponse
    {
        if ($user->is_admin) {
            throw new NotFoundHttpException();
        }

        $validated = $request->validate(['is_rider' => ['required', 'boolean']]);
        $user->forceFill(['is_rider' => $validated['is_rider']])->save();

        return response()->json(['data' => ['id' => $user->id, 'is_rider' => (bool) $user->is_rider]]);
    }

    public function riders(): JsonResponse
    {
        return response()->json([
            'data' => User::where('is_rider', true)->orderBy('name')->get(['id', 'name', 'email']),
        ]);
    }
}
