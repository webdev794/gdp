<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Store;
use App\Support\Geo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeliveryController extends Controller
{
    /**
     * Given a lat/lng, report the nearest active store, distance, whether it's
     * in that store's delivery radius, and an estimated delivery time.
     */
    public function __invoke(Request $request): JsonResponse
    {
        $data = $request->validate([
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
        ]);

        $stores = Store::query()->where('is_active', true)
            ->whereNotNull('latitude')->whereNotNull('longitude')->get();

        if ($stores->isEmpty()) {
            return response()->json(['data' => ['configured' => false, 'deliverable' => true, 'minutes' => 15]]);
        }

        $best = null;
        foreach ($stores as $store) {
            $km = Geo::haversineKm((float) $store->latitude, (float) $store->longitude, (float) $data['lat'], (float) $data['lng']);
            if ($best === null || $km < $best['distance_km']) {
                $best = ['store' => $store, 'distance_km' => $km];
            }
        }

        // ~25 km/h effective delivery speed, plus a 6 minute prep floor.
        $minutes = max(6, (int) ceil(6 + ($best['distance_km'] / 25) * 60));

        return response()->json(['data' => [
            'configured' => true,
            'deliverable' => $best['distance_km'] <= $best['store']->delivery_radius_km,
            'distance_km' => round($best['distance_km'], 2),
            'radius_km' => $best['store']->delivery_radius_km,
            'minutes' => $minutes,
            'store_name' => $best['store']->name,
        ]]);
    }
}
