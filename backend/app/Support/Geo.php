<?php

namespace App\Support;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class Geo
{
    /**
     * Great-circle distance between two lat/lng points, in kilometres.
     */
    public static function haversineKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthKm = 6371.0088;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;

        return $earthKm * 2 * asin(min(1.0, sqrt($a)));
    }

    /**
     * Best-effort forward geocode via OpenStreetMap Nominatim. Cached for a day.
     * Returns [lat, lng] or [null, null].
     *
     * @return array{0: float|null, 1: float|null}
     */
    public static function geocode(string $query): array
    {
        $query = trim($query);
        if ($query === '') {
            return [null, null];
        }

        return Cache::remember('geocode:'.md5($query), now()->addDay(), function () use ($query) {
            try {
                $response = Http::withHeaders(['Accept-Language' => 'en'])
                    ->timeout(6)
                    ->get('https://nominatim.openstreetmap.org/search', [
                        'format' => 'jsonv2',
                        'limit' => 1,
                        'q' => $query,
                    ]);

                $hit = $response->json(0);

                if (is_array($hit) && isset($hit['lat'], $hit['lon'])) {
                    return [(float) $hit['lat'], (float) $hit['lon']];
                }
            } catch (\Throwable) {
                // fall through
            }

            return [null, null];
        });
    }
}
