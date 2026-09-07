<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $orders = $request->user()->orders()
            ->with('items')
            ->latest()
            ->paginate(20);

        return response()->json([
            'data' => $orders->items(),
            'meta' => [
                'current_page' => $orders->currentPage(),
                'last_page' => $orders->lastPage(),
                'total' => $orders->total(),
            ],
        ]);
    }

    public function show(Request $request, Order $order): JsonResponse
    {
        abort_unless($order->user_id === $request->user()->id, 404);

        return response()->json(['data' => $order->load('items')]);
    }

    /**
     * Switch an unpaid order between card payment and cash on delivery before
     * any money has moved. Lets a customer back out of the card screen without
     * re-doing checkout.
     */
    public function setPaymentMethod(Request $request, Order $order): JsonResponse
    {
        abort_unless($order->user_id === $request->user()->id, 404);

        $validated = $request->validate([
            'payment_method' => ['required', Rule::in(['card', 'cod'])],
        ]);

        if ($order->payment_status !== 'pending' || ! in_array($order->status, ['pending_payment', 'confirmed'], true)) {
            return response()->json(['message' => 'This order can no longer change its payment method.'], 422);
        }

        if ($validated['payment_method'] === 'cod' && ! Setting::get('cod_enabled', false)) {
            return response()->json(['message' => 'Cash on delivery is not available right now.'], 422);
        }

        $order->update([
            'payment_method' => $validated['payment_method'],
            'status' => $validated['payment_method'] === 'cod' ? 'confirmed' : 'pending_payment',
        ]);

        return response()->json(['data' => $order->load('items')]);
    }

    /**
     * Customer-initiated cancellation, allowed until the order leaves the store
     * (confirmed / packing / ready_for_delivery). A paid order is flagged
     * refund_pending for an admin to process; an unpaid one is voided outright.
     */
    public function cancel(Request $request, Order $order): JsonResponse
    {
        abort_unless($order->user_id === $request->user()->id, 404);

        if (! $order->canTransitionTo('cancelled')) {
            return response()->json([
                'message' => 'This order can no longer be cancelled. Please contact support.',
            ], 422);
        }

        $order->update([
            'status' => 'cancelled',
            'payment_status' => $order->payment_status === 'paid' ? 'refund_pending' : 'cancelled',
        ]);

        return response()->json(['data' => $order->load('items')]);
    }
}
