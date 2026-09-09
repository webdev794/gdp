<?php

namespace App\Support;

use App\Models\Order;
use App\Models\Setting;
use App\Models\User;

/**
 * Picks the delivery rider for an order: among the riders linked to the order's
 * fulfilling store, the one nearest the store, with a nudge toward riders who
 * aren't already loaded up.
 */
class RiderAssignment
{
    /**
     * Each delivery a rider already has counts as this many extra km when
     * ranking, so an idle rider a bit further out beats a busy rider next door.
     */
    private const BUSY_PENALTY_KM = 6.0;

    /** Deliveries that count as "still on the rider's plate". */
    private const ACTIVE_STATUSES = ['ready_for_delivery', 'out_for_delivery'];

    public static function isEnabled(): bool
    {
        return (bool) Setting::get('rider_auto_assign', true);
    }

    /**
     * Assign a rider to the order and return them, or null when auto-assignment
     * is off, the order can't be auto-assigned, or no rider is eligible (the
     * order then stays in the first-come pool).
     */
    public static function assign(Order $order): ?User
    {
        if (! self::isEnabled() || $order->delivery_partner_id || ! $order->store_id) {
            return null;
        }

        $store = $order->relationLoaded('store') ? $order->store : $order->store()->first();

        if (! $store || $store->latitude === null || $store->longitude === null) {
            return null;
        }

        $riders = User::query()
            ->where('is_rider', true)
            ->where('rider_is_active', true)
            ->whereHas('stores', fn ($query) => $query->whereKey($store->id))
            ->withCount(['deliveries as active_deliveries' => fn ($query) => $query
                ->whereIn('status', self::ACTIVE_STATUSES)])
            ->get();

        $best = null;

        foreach ($riders as $rider) {
            $location = $rider->riderLocation();
            if ($location === null) {
                continue; // no live fix and no base — can't place this rider
            }

            $km = Geo::haversineKm(
                $location['lat'], $location['lng'],
                (float) $store->latitude, (float) $store->longitude,
            );
            $score = $km + $rider->active_deliveries * self::BUSY_PENALTY_KM;

            if ($best === null || $score < $best['score']) {
                $best = ['rider' => $rider, 'score' => $score];
            }
        }

        if ($best === null) {
            return null;
        }

        $order->update([
            'delivery_partner_id' => $best['rider']->id,
            'courier_name' => $best['rider']->name,
        ]);

        return $best['rider'];
    }
}
