<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminOrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['sometimes', 'string'],
        ]);

        $orders = Order::query()
            ->with(['items', 'user:id,name,email'])
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->latest()
            ->paginate(25);

        return response()->json([
            'data' => $orders->items(),
            'meta' => [
                'current_page' => $orders->currentPage(),
                'last_page' => $orders->lastPage(),
                'total' => $orders->total(),
            ],
        ]);
    }

    public function show(Order $order): JsonResponse
    {
        return response()->json(['data' => $order->load(['items', 'user:id,name,email'])]);
    }

    public function update(Request $request, Order $order): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['sometimes', Rule::in(array_keys(Order::DELIVERY_TRANSITIONS))],
            'courier_name' => ['sometimes', 'nullable', 'string', 'max:120'],
        ]);

        if (! array_key_exists('status', $validated) && ! array_key_exists('courier_name', $validated)) {
            return response()->json(['message' => 'Provide a status change or a courier assignment.'], 422);
        }

        if (isset($validated['status']) && ! $order->canTransitionTo($validated['status'])) {
            return response()->json([
                'message' => "An order that is {$order->status} cannot move to {$validated['status']}.",
            ], 422);
        }

        $order->update($validated);

        return response()->json(['data' => $order->load(['items', 'user:id,name,email'])]);
    }
}
