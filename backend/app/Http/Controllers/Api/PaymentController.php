<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\StripeEvent;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Stripe\Exception\ApiErrorException;
use Stripe\StripeClient;
use Stripe\Webhook;

class PaymentController extends Controller
{
    public function intent(Request $request, Order $order): JsonResponse
    {
        abort_unless($order->user_id === $request->user()->id, 404);

        if (! config('services.stripe.secret')) {
            return response()->json([
                'message' => 'Stripe is not configured. Add STRIPE_SECRET to the backend environment.',
            ], 503);
        }

        if ($order->payment_status === 'paid') {
            return response()->json(['data' => ['order_id' => $order->id, 'payment_status' => 'paid']]);
        }

        if ($order->status === 'cancelled' || $order->payment_status === 'cancelled') {
            return response()->json(['message' => 'This order has been cancelled.'], 422);
        }

        $stripe = new StripeClient(config('services.stripe.secret'));

        try {
            $intent = $order->stripe_payment_intent_id
                ? $stripe->paymentIntents->retrieve($order->stripe_payment_intent_id)
                : $stripe->paymentIntents->create([
                    'amount' => $order->total_cents,
                    'currency' => 'usd',
                    'automatic_payment_methods' => ['enabled' => true],
                    'metadata' => ['order_id' => (string) $order->id],
                ]);
        } catch (ApiErrorException $exception) {
            Log::error('Stripe PaymentIntent failed', ['order_id' => $order->id, 'error' => $exception->getMessage()]);

            return response()->json(['message' => 'Payment could not be set up. Please try again.'], 502);
        }

        if ($order->stripe_payment_intent_id !== $intent->id) {
            $order->update(['stripe_payment_intent_id' => $intent->id]);
        }

        // Fallback for a missed or delayed webhook: if Stripe has already settled
        // the intent, confirm the order now from the authoritative source.
        if ($intent->status === 'succeeded') {
            DB::transaction(function () use ($order): void {
                $locked = Order::whereKey($order->id)->lockForUpdate()->first();
                $this->markPaid($locked);
                $order->setRawAttributes($locked->getAttributes(), true);
            });

            Log::info('Order reconciled from Stripe on intent request', ['order_id' => $order->id]);

            return response()->json(['data' => ['order_id' => $order->id, 'payment_status' => 'paid']]);
        }

        return response()->json([
            'data' => [
                'order_id' => $order->id,
                'client_secret' => $intent->client_secret,
            ],
        ]);
    }

    public function webhook(Request $request): JsonResponse
    {
        if (! config('services.stripe.webhook_secret')) {
            Log::error('Stripe webhook secret is not configured.');

            return response()->json([
                'message' => 'Stripe webhook processing is not configured.',
            ], 503);
        }

        try {
            $event = Webhook::constructEvent(
                $request->getContent(),
                $request->header('Stripe-Signature'),
                config('services.stripe.webhook_secret')
            );
        } catch (\Throwable $exception) {
            Log::warning('Invalid Stripe webhook', ['error' => $exception->getMessage()]);

            return response()->json(['message' => 'Invalid webhook.'], 400);
        }

        if (StripeEvent::whereKey($event->id)->exists()) {
            Log::info('Duplicate Stripe event ignored', ['event' => $event->id, 'type' => $event->type]);

            return response()->json(['received' => true]);
        }

        try {
            DB::transaction(function () use ($event): void {
                // Recording the event id first; the primary key is the last-resort
                // guard against two deliveries racing past the check above.
                StripeEvent::create([
                    'id' => $event->id,
                    'type' => $event->type,
                    'processed_at' => now(),
                ]);

                $this->applyPaymentEvent($event);
            });
        } catch (UniqueConstraintViolationException) {
            Log::info('Duplicate Stripe event ignored', ['event' => $event->id, 'type' => $event->type]);
        }

        return response()->json(['received' => true]);
    }

    /**
     * Move the order through its payment lifecycle. Transitions are guarded so
     * that out-of-order deliveries (a late failure after a success, a cancel
     * after payment) can never contradict a settled order.
     */
    private function applyPaymentEvent(object $event): void
    {
        $handled = ['payment_intent.succeeded', 'payment_intent.payment_failed', 'payment_intent.canceled'];

        if (! in_array($event->type, $handled, true)) {
            Log::info('Unhandled Stripe event type', ['event' => $event->id, 'type' => $event->type]);

            return;
        }

        $intentId = $event->data->object->id ?? null;
        $order = $intentId
            ? Order::where('stripe_payment_intent_id', $intentId)->lockForUpdate()->first()
            : null;

        if (! $order) {
            Log::warning('Stripe event has no matching order', ['event' => $event->id, 'payment_intent' => $intentId]);

            return;
        }

        $before = ['status' => $order->status, 'payment_status' => $order->payment_status];

        match ($event->type) {
            'payment_intent.succeeded' => $this->markPaid($order),
            'payment_intent.payment_failed' => $this->markFailed($order),
            'payment_intent.canceled' => $this->markCancelled($order),
        };

        Log::info('Stripe event applied', [
            'event' => $event->id,
            'type' => $event->type,
            'order_id' => $order->id,
            'from' => $before,
            'to' => ['status' => $order->status, 'payment_status' => $order->payment_status],
        ]);
    }

    private function markPaid(Order $order): void
    {
        if ($order->payment_status === 'paid') {
            return;
        }

        $order->update(['payment_status' => 'paid', 'status' => 'confirmed']);
    }

    private function markFailed(Order $order): void
    {
        // Never override a settled order; leave status at pending_payment so the
        // customer can retry the same order.
        if ($order->payment_status !== 'pending') {
            return;
        }

        $order->update(['payment_status' => 'failed']);
    }

    private function markCancelled(Order $order): void
    {
        if (! in_array($order->payment_status, ['pending', 'failed'], true)) {
            return;
        }

        $order->update(['payment_status' => 'cancelled', 'status' => 'cancelled']);
    }
}
