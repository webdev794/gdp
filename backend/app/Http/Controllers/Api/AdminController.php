<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\JsonResponse;
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
                'awaiting_fulfilment' => (int) $ordersByStatus->only(['confirmed', 'preparing', 'out_for_delivery'])->sum(),
                'revenue_cents' => (int) Order::where('payment_status', 'paid')->sum('total_cents'),
                'customers' => User::where('is_admin', false)->count(),
                'products' => Product::count(),
                'low_stock' => Product::where('inventory_quantity', '<=', 5)->count(),
            ],
        ]);
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
                'joined_at' => $user->created_at,
                'addresses' => $user->addresses()->latest()->get(),
                'orders' => $user->orders()->with('items')->latest()->get(),
            ],
        ]);
    }
}
