<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
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

        return response()->json([
            'data' => [
                'orders_by_status' => $ordersByStatus,
                'orders_total' => (int) $ordersByStatus->sum(),
                'awaiting_fulfilment' => (int) $ordersByStatus->only(['confirmed', 'packing', 'ready_for_delivery', 'out_for_delivery'])->sum(),
                'revenue_cents' => (int) Order::where('payment_status', 'paid')->sum('total_cents'),
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
     * One period-over-period comparison for the dashboard: the current
     * period-to-date against the equivalent earlier period. `preset` picks the
     * span (day / two_day / week / month / six_month / year) or `custom` with a
     * rolling `days` window. Returns window totals plus an aligned per-bucket
     * series so the client can draw current vs previous in a single chart.
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

        [$curStart, $prevStart, $unit, $curLabel, $prevLabel] = $this->comparePreset($preset, $days, $now);

        $prevEnd = $prevStart->copy()->addSeconds($curStart->diffInSeconds($now));

        // Bucket labels come from walking the current window.
        $labels = [];
        $cursor = $curStart->copy();
        while ($cursor < $now && count($labels) < 400) {
            $labels[] = match ($unit) {
                'hour' => $cursor->format('M j ga'),
                'day' => $cursor->format('M j'),
                'month' => $cursor->format('M Y'),
            };
            match ($unit) {
                'hour' => $cursor->addHour(),
                'day' => $cursor->addDay(),
                'month' => $cursor->addMonthNoOverflow(),
            };
        }
        $count = max(1, count($labels));

        $bucketIndex = fn (Carbon $start, Carbon $moment): int => match ($unit) {
            'hour' => intdiv($moment->getTimestamp() - $start->getTimestamp(), 3600),
            'day' => (int) $start->copy()->startOfDay()->diffInDays($moment),
            'month' => (int) $start->diffInMonths($moment),
        };

        $cur = array_fill(0, $count, ['orders' => 0, 'revenue_cents' => 0]);
        $prev = $cur;
        $curTotals = ['orders' => 0, 'paid_orders' => 0, 'revenue_cents' => 0];
        $prevTotals = $curTotals;

        Order::query()
            ->where('created_at', '>=', $prevStart)
            ->where('created_at', '<', $now)
            ->get(['created_at', 'payment_status', 'total_cents'])
            ->each(function (Order $order) use (
                &$cur, &$prev, &$curTotals, &$prevTotals,
                $curStart, $now, $prevStart, $prevEnd, $bucketIndex, $count
            ) {
                $moment = $order->created_at;
                $paid = $order->payment_status === 'paid';
                $revenue = $paid ? (int) $order->total_cents : 0;

                if ($moment >= $curStart && $moment < $now) {
                    $curTotals['orders']++;
                    $curTotals['paid_orders'] += $paid ? 1 : 0;
                    $curTotals['revenue_cents'] += $revenue;
                    $index = $bucketIndex($curStart, $moment);
                    if ($index >= 0 && $index < $count) {
                        $cur[$index]['orders']++;
                        $cur[$index]['revenue_cents'] += $revenue;
                    }
                } elseif ($moment >= $prevStart && $moment < $prevEnd) {
                    $prevTotals['orders']++;
                    $prevTotals['paid_orders'] += $paid ? 1 : 0;
                    $prevTotals['revenue_cents'] += $revenue;
                    $index = $bucketIndex($prevStart, $moment);
                    if ($index >= 0 && $index < $count) {
                        $prev[$index]['orders']++;
                        $prev[$index]['revenue_cents'] += $revenue;
                    }
                }
            });

        $series = [];
        foreach ($labels as $index => $label) {
            $series[] = ['label' => $label, 'current' => $cur[$index], 'previous' => $prev[$index]];
        }

        return response()->json(['data' => [
            'preset' => $preset,
            'days' => $preset === 'custom' ? $days : null,
            'bucket' => $unit,
            'current' => ['label' => $curLabel, 'from' => $curStart->toIso8601String(), 'to' => $now->toIso8601String(), ...$curTotals],
            'previous' => ['label' => $prevLabel, 'from' => $prevStart->toIso8601String(), 'to' => $prevEnd->toIso8601String(), ...$prevTotals],
            'series' => $series,
        ]]);
    }

    /**
     * @return array{0: Carbon, 1: Carbon, 2: string, 3: string, 4: string}
     *         [currentStart, previousStart, bucketUnit, currentLabel, previousLabel]
     */
    private function comparePreset(string $preset, ?int $days, Carbon $now): array
    {
        return match ($preset) {
            'day' => [$now->copy()->startOfDay(), $now->copy()->startOfDay()->subDay(), 'hour', 'Today', 'Yesterday'],
            'two_day' => [$now->copy()->subDays(2), $now->copy()->subDays(4), 'hour', 'Last 2 days', 'Previous 2 days'],
            'week' => [$now->copy()->startOfWeek(Carbon::MONDAY), $now->copy()->startOfWeek(Carbon::MONDAY)->subWeek(), 'day', 'This week', 'Last week'],
            'month' => [$now->copy()->startOfMonth(), $now->copy()->startOfMonth()->subMonthNoOverflow(), 'day', 'This month', 'Last month'],
            'six_month' => [$now->copy()->subMonthsNoOverflow(6), $now->copy()->subMonthsNoOverflow(12), 'month', 'Last 6 months', 'Previous 6 months'],
            'year' => [$now->copy()->startOfYear(), $now->copy()->startOfYear()->subYear(), 'month', 'This year', 'Last year'],
            'custom' => [
                $now->copy()->subDays($days),
                $now->copy()->subDays($days * 2),
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
