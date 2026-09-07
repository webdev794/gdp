<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Store;
use App\Support\Geo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GeocodeController extends Controller
{
    /**
     * Forward address search, biased toward the active store's area so results
     * are local whether the store is in the USA, India, or anywhere else.
     */
    public function search(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'q' => ['required', 'string', 'min:3', 'max:200'],
        ]);

        [$lat, $lng, $maxKm] = $this->biasCentre();

        return response()->json(['data' => Geo::search($validated['q'], $lat, $lng, $maxKm)]);
    }

    /**
     * Reverse geocode a dropped pin to a readable address.
     */
    public function reverse(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
        ]);

        return response()->json(['data' => Geo::reverse((float) $validated['lat'], (float) $validated['lng'])]);
    }

    /**
     * Centre + how far a forward-search result may sit from it (roughly four
     * delivery radii, so results stay in the serviceable neighbourhood).
     *
     * @return array{0: float|null, 1: float|null, 2: float}
     */
    private function biasCentre(): array
    {
        $store = Store::query()->where('is_active', true)
            ->whereNotNull('latitude')->whereNotNull('longitude')
            ->orderBy('id')->first();

        if (! $store) {
            return [null, null, 40.0];
        }

        return [(float) $store->latitude, (float) $store->longitude, max(25.0, $store->delivery_radius_km * 4.0)];
    }
}
