<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\SupportThread;
use App\Notifications\DeliveryHandoverCode;
use App\Notifications\RiderMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class RiderController extends Controller
{
    public function orders(Request $request): JsonResponse
    {
        $rider = $request->user();
        $me = $rider->id;

        // Include orders still being packed so the rider sees what's coming;
        // the delivery actions only unlock once it's ready_for_delivery.
        $assigned = Order::query()
            ->where('delivery_partner_id', $me)
            ->whereIn('status', ['confirmed', 'packing', 'ready_for_delivery', 'out_for_delivery'])
            ->with(['items', 'user:id,name,phone'])
            ->latest()
            ->get();

        // Once a rider is linked to stores, their pool is scoped to those stores
        // (plus any order with no store recorded — older data visible to all). A
        // rider with no store links yet sees the whole pool, as before.
        $storeIds = $rider->stores()->pluck('stores.id');

        $pool = Order::query()
            ->whereNull('delivery_partner_id')
            ->where('status', 'ready_for_delivery')
            ->when($storeIds->isNotEmpty(), fn ($query) => $query->where(fn ($q) => $q
                ->whereNull('store_id')
                ->orWhereIn('store_id', $storeIds)))
            ->with(['items', 'user:id,name,phone'])
            ->latest()
            ->get();

        return response()->json([
            'data' => [
                'assigned' => $assigned->map($this->row(...))->values(),
                'pool' => $pool->map($this->row(...))->values(),
            ],
        ]);
    }

    /**
     * The rider's own dashboard: lifetime deliveries, how this week and month
     * compare with the one before, their star rating, the share of deliveries
     * confirmed by a handover code, cash collected, and their most recent
     * ratings (scores and dates only — written feedback is for the admin).
     */
    public function stats(Request $request): JsonResponse
    {
        $rider = $request->user();
        $me = $rider->id;

        $delivered = Order::query()
            ->where('delivery_partner_id', $me)
            ->where('status', 'completed');

        $since = fn ($from, $to = null) => (clone $delivered)
            ->where('delivered_at', '>=', $from)
            ->when($to, fn ($q) => $q->where('delivered_at', '<', $to))
            ->count();

        $now = now();
        $weekAgo = $now->copy()->subDays(7);
        $twoWeeksAgo = $now->copy()->subDays(14);
        $monthAgo = $now->copy()->subDays(30);
        $twoMonthsAgo = $now->copy()->subDays(60);

        $total = (clone $delivered)->count();
        $verified = (clone $delivered)->where('delivery_verified', true)->count();
        $codCents = (int) Order::query()
            ->where('delivery_partner_id', $me)
            ->where('status', 'completed')
            ->where('payment_method', 'cod')
            ->where('payment_status', 'paid')
            ->sum('total_cents');

        $recent = $rider->riderReviews()
            ->latest()
            ->limit(10)
            ->get(['rating', 'source', 'created_at'])
            ->map(fn ($r) => ['rating' => (int) $r->rating, 'source' => $r->source, 'at' => $r->created_at]);

        return response()->json(['data' => [
            'deliveries_total' => $total,
            'deliveries_week' => $since($weekAgo),
            'deliveries_week_prev' => $since($twoWeeksAgo, $weekAgo),
            'deliveries_month' => $since($monthAgo),
            'deliveries_month_prev' => $since($twoMonthsAgo, $monthAgo),
            'rating_avg' => $rider->rider_rating_avg !== null ? (float) $rider->rider_rating_avg : null,
            'rating_count' => (int) $rider->rider_rating_count,
            'verified_rate' => $total ? round($verified / $total, 3) : null,
            'cod_collected_cents' => $codCents,
            'recent_ratings' => $recent,
        ]]);
    }

    public function claim(Request $request, Order $order): JsonResponse
    {
        if ($order->status !== 'ready_for_delivery'
            || ($order->delivery_partner_id && $order->delivery_partner_id !== $request->user()->id)) {
            return response()->json(['message' => 'This order is not available to pick up.'], 422);
        }

        $order->update([
            'delivery_partner_id' => $request->user()->id,
            'courier_name' => $request->user()->name,
            'status' => 'out_for_delivery',
        ]);

        return response()->json(['data' => $this->row($order->fresh(['items', 'user:id,name,phone']))]);
    }

    public function status(Request $request, Order $order): JsonResponse
    {
        $this->assertMine($request, $order);

        // "Picked up" only. Completing a delivery goes through deliver() so it
        // carries an OTP confirmation (or a recorded override).
        $validated = $request->validate([
            'status' => ['required', Rule::in(['out_for_delivery'])],
        ]);

        if (! $order->canTransitionTo($validated['status'])) {
            return response()->json(['message' => "Cannot move a {$order->status} order to {$validated['status']}."], 422);
        }

        $order->update(['status' => $validated['status']]);

        return response()->json(['data' => $this->row($order->fresh(['items', 'user:id,name,phone']))]);
    }

    /**
     * At the door: generate a short handover code and send it to the customer.
     * The customer reads it back to the rider, who confirms the delivery.
     */
    public function sendDeliveryOtp(Request $request, Order $order): JsonResponse
    {
        $this->assertMine($request, $order);

        if ($order->status !== 'out_for_delivery') {
            return response()->json(['message' => 'Start the delivery before requesting a code.'], 422);
        }

        $ttl = 15;
        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $order->forceFill([
            'delivery_code' => $code,
            'delivery_code_expires_at' => now()->addMinutes($ttl),
        ])->save();

        $email = $order->user?->email;
        if ($email) {
            Notification::route('mail', $email)->notify(new DeliveryHandoverCode($order->id, $code, $ttl));
        }
        if (config('app.debug')) {
            Log::info("Delivery code for order #{$order->id} ({$email}): {$code}");
        }

        return response()->json(['data' => [
            'sent' => (bool) $email,
            'to' => $email ? $this->maskEmail($email) : null,
            'expires_in' => $ttl * 60,
        ]]);
    }

    /**
     * Complete the delivery. Either verify the handover code the customer gave
     * (`code`), or — when that can't be done — record an unverified handover
     * (`override` + a short `note`) so the store still has the evidence.
     */
    public function deliver(Request $request, Order $order): JsonResponse
    {
        $this->assertMine($request, $order);

        if (! $order->canTransitionTo('completed')) {
            return response()->json(['message' => "A {$order->status} order can't be marked delivered."], 422);
        }

        $data = $request->validate([
            'code' => ['required_without:override', 'nullable', 'string', 'max:8'],
            'override' => ['sometimes', 'boolean'],
            'note' => ['required_if:override,true', 'nullable', 'string', 'max:300'],
        ]);

        $override = (bool) ($data['override'] ?? false);

        if (! $override) {
            if (! $order->deliveryCodeActive() || ! hash_equals((string) $order->delivery_code, trim((string) $data['code']))) {
                throw ValidationException::withMessages([
                    'code' => ['That code is wrong or has expired. Ask the customer to check their email, or use "mark delivered without code".'],
                ]);
            }
        }

        $order->forceFill([
            'status' => 'completed',
            'delivered_at' => now(),
            'delivery_verified' => ! $override,
            'delivery_note' => $override ? trim((string) $data['note']) : null,
            'delivery_code' => null,
            'delivery_code_expires_at' => null,
        ])->save();

        return response()->json(['data' => $this->row($order->fresh(['items', 'user:id,name,phone']))]);
    }

    private function maskEmail(string $email): string
    {
        [$name, $domain] = array_pad(explode('@', $email, 2), 2, '');
        $head = mb_substr($name, 0, 1);
        $tail = mb_strlen($name) > 1 ? mb_substr($name, -1) : '';

        return "{$head}***{$tail}@{$domain}";
    }

    /**
     * The rider app pings its live position here; auto-assignment prefers it
     * over the base while it's fresh (< 15 min old).
     */
    public function location(Request $request): JsonResponse
    {
        $data = $request->validate([
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
        ]);

        $request->user()->forceFill([
            'rider_last_lat' => $data['lat'],
            'rider_last_lng' => $data['lng'],
            'rider_last_located_at' => now(),
        ])->save();

        return response()->json(['data' => ['ok' => true]]);
    }

    public function cashCollected(Request $request, Order $order): JsonResponse
    {
        $this->assertMine($request, $order);

        if (! $order->isCashOnDelivery()) {
            return response()->json(['message' => 'This order was not cash on delivery.'], 422);
        }

        if ($order->payment_status !== 'paid') {
            $order->update(['payment_status' => 'paid']);
        }

        return response()->json(['data' => $this->row($order->fresh(['items', 'user:id,name,phone']))]);
    }

    /**
     * Rider <-> customer chat for a delivery. Reuses the support-thread system,
     * so the customer sees it in their existing "Get help" inbox and staff see
     * it in the admin Support tab.
     */
    public function messages(Request $request, Order $order): JsonResponse
    {
        $this->assertMine($request, $order);

        return response()->json(['data' => $this->threadPayload($this->threadFor($order), $request->user()->id)]);
    }

    public function postMessage(Request $request, Order $order): JsonResponse
    {
        $this->assertMine($request, $order);
        $validated = $request->validate(['body' => ['required', 'string', 'max:2000']]);

        $thread = $this->threadFor($order);
        if ($thread->status === 'resolved') {
            $thread->forceFill(['status' => 'open', 'resolved_at' => null])->save();
        }
        // Rider messages read as "staff" on the customer's side.
        $thread->post($request->user(), $validated['body'], isStaff: true);

        // Delivery chat is time-sensitive — nudge the customer by email too.
        $email = $order->user?->email;
        if ($email) {
            Notification::route('mail', $email)->notify(new RiderMessage($order->id, $validated['body']));
        }

        return response()->json(['data' => $this->threadPayload($thread->fresh(), $request->user()->id)]);
    }

    private function threadFor(Order $order): SupportThread
    {
        $thread = SupportThread::where('order_id', $order->id)
            ->where('user_id', $order->user_id)
            ->orderBy('id')
            ->first();

        if (! $thread) {
            $thread = SupportThread::create([
                'user_id' => $order->user_id,
                'order_id' => $order->id,
                'issue_type' => 'delivery',
                'status' => 'open',
            ]);
            $thread->post(null, "Delivery chat for order #{$order->id} — your rider will message you here.", system: true);
        }

        return $thread;
    }

    /**
     * @return array<string, mixed>
     */
    private function threadPayload(SupportThread $thread, int $riderId): array
    {
        $thread->load('messages');

        return [
            'thread_id' => $thread->id,
            'status' => $thread->status,
            'messages' => $thread->messages->map(fn ($m) => [
                'id' => $m->id,
                'body' => $m->body,
                'mine' => $m->user_id === $riderId,
                'from' => $m->user_id === null ? 'system' : ($m->is_staff ? 'staff' : 'customer'),
                'at' => $m->created_at,
            ])->values(),
        ];
    }

    private function assertMine(Request $request, Order $order): void
    {
        abort_unless($order->delivery_partner_id === $request->user()->id, 404);
    }

    /**
     * @return array<string, mixed>
     */
    private function row(Order $order): array
    {
        $codDue = $order->isCashOnDelivery() && $order->payment_status !== 'paid' ? (int) $order->total_cents : 0;

        return [
            'id' => $order->id,
            'status' => $order->status,
            'customer_name' => $order->user?->name,
            'customer_phone' => $order->delivery_address['phone'] ?? $order->user?->phone,
            'delivery_address' => $order->delivery_address,
            'delivery_instructions' => $order->delivery_instructions,
            'payment_method' => $order->payment_method,
            'payment_status' => $order->payment_status,
            'total_cents' => (int) $order->total_cents,
            'cod_due' => $codDue,
            'delivery_code_active' => $order->deliveryCodeActive(),
            'delivered_at' => $order->delivered_at,
            'delivery_verified' => $order->delivery_verified,
            'items' => $order->items->map(fn ($i) => [
                'name' => $i->product_name.($i->variant_label ? " · {$i->variant_label}" : ''),
                'quantity' => $i->quantity,
            ])->values(),
        ];
    }
}
