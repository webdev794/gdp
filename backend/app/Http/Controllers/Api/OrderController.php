<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Setting;
use App\Models\Store;
use App\Support\Branding;
use App\Support\Geo;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\Response;

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
     * A printable bill (PDF) for the customer's own order: the shop address, every
     * line with its regular and paid price, the fee breakdown and the total paid.
     *
     * Only issued once the order is a committed, payable order — a card order
     * that has been paid, or a cash-on-delivery order that has been placed
     * (payment is collected on hand-off, so the bill goes out with the order).
     * Not available while a card payment is still pending, or once cancelled.
     */
    public function receipt(Request $request, Order $order): Response
    {
        abort_unless($order->user_id === $request->user()->id, 404);

        $billable = $order->payment_status === 'paid' || $order->isCashOnDelivery();
        abort_unless($billable && $order->status !== 'cancelled', 403, 'The bill for this order is not available yet.');

        // Orders placed before line-level price snapshots fall back to the
        // product's / variant's current regular price, the same way the cart does.
        $order->load('items.product', 'items.productVariant');

        $pdf = Pdf::setOption(['isFontSubsettingEnabled' => true])
            ->loadView('receipts.order', [
                'order' => $order,
                'store' => $this->fulfillingStore($order),
                'branding' => Branding::current(),
            ]);

        return $pdf->download("bill-order-{$order->id}.pdf");
    }

    /**
     * The shop the bill is issued from: the active store nearest the delivery
     * address when we have coordinates, otherwise the first active store.
     */
    private function fulfillingStore(Order $order): ?Store
    {
        $stores = Store::query()->where('is_active', true)->orderBy('id')->get();

        if ($stores->isEmpty()) {
            return null;
        }

        $lat = $order->delivery_address['latitude'] ?? null;
        $lng = $order->delivery_address['longitude'] ?? null;

        if ($lat !== null && $lng !== null) {
            $nearest = Geo::nearestStore($stores, (float) $lat, (float) $lng);
            if ($nearest) {
                return $nearest['store'];
            }
        }

        return $stores->first();
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
