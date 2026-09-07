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
            ->with(['items', 'user:id,name,email,phone', 'deliveryPartner:id,name'])
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
        return response()->json(['data' => $order->load(['items', 'user:id,name,email,phone'])]);
    }

    public function update(Request $request, Order $order): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['sometimes', Rule::in(array_keys(Order::DELIVERY_TRANSITIONS))],
            'courier_name' => ['sometimes', 'nullable', 'string', 'max:120'],
            'delivery_partner_id' => ['sometimes', 'nullable', 'integer', 'exists:users,id'],
            'cash_collected' => ['sometimes', 'boolean'],
            'refunded' => ['sometimes', 'boolean'],
        ]);

        if (! array_key_exists('status', $validated)
            && ! array_key_exists('courier_name', $validated)
            && ! array_key_exists('delivery_partner_id', $validated)
            && ! array_key_exists('cash_collected', $validated)
            && ! array_key_exists('refunded', $validated)) {
            return response()->json(['message' => 'Provide a status change, a courier assignment, or a payment update.'], 422);
        }

        if (isset($validated['status']) && ! $order->canTransitionTo($validated['status'])) {
            return response()->json([
                'message' => "An order that is {$order->status} cannot move to {$validated['status']}.",
            ], 422);
        }

        $changes = array_intersect_key($validated, array_flip(['status', 'courier_name']));

        // Assigning a delivery partner: must be a rider, and it also fills the
        // display courier_name. A null clears both.
        if (array_key_exists('delivery_partner_id', $validated)) {
            $rider = $validated['delivery_partner_id']
                ? \App\Models\User::find($validated['delivery_partner_id'])
                : null;

            if ($validated['delivery_partner_id'] && ! $rider?->is_rider) {
                return response()->json(['message' => 'That user is not a delivery rider.'], 422);
            }

            $changes['delivery_partner_id'] = $rider?->id;
            $changes['courier_name'] = $rider?->name;
        }

        // Cash collected on hand-off settles a cash-on-delivery order.
        if (($validated['cash_collected'] ?? false)
            && $order->isCashOnDelivery()
            && $order->payment_status !== 'paid') {
            $changes['payment_status'] = 'paid';
        }

        // Cancelling an unpaid cash-on-delivery order also voids its payment,
        // mirroring the Stripe cancellation path.
        if (($changes['status'] ?? null) === 'cancelled'
            && $order->isCashOnDelivery()
            && $order->payment_status === 'pending') {
            $changes['payment_status'] = 'cancelled';
        }

        // Admin has issued the refund for a customer-cancelled paid order.
        if (($validated['refunded'] ?? false) && $order->payment_status === 'refund_pending') {
            $changes['payment_status'] = 'refunded';
        }

        $order->update($changes);

        return response()->json(['data' => $order->load(['items', 'user:id,name,email,phone', 'deliveryPartner:id,name'])]);
    }
}
