<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\SupportThread;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

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

        $validated = $request->validate([
            'status' => ['required', Rule::in(['out_for_delivery', 'completed'])],
        ]);

        if (! $order->canTransitionTo($validated['status'])) {
            return response()->json(['message' => "Cannot move a {$order->status} order to {$validated['status']}."], 422);
        }

        $order->update(['status' => $validated['status']]);

        return response()->json(['data' => $this->row($order->fresh(['items', 'user:id,name,phone']))]);
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
                'issue_type' => 'other',
                'status' => 'open',
            ]);
            $thread->post(null, "Your delivery rider started a chat about order #{$order->id}.", system: true);
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
            'items' => $order->items->map(fn ($i) => [
                'name' => $i->product_name.($i->variant_label ? " · {$i->variant_label}" : ''),
                'quantity' => $i->quantity,
            ])->values(),
        ];
    }
}
