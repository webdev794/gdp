<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use App\Support\StoreLocator;
use Illuminate\Http\JsonResponse;

/**
 * Admin clean-up of customers' saved addresses that no store can deliver to:
 * outside every active store's delivery radius, or with no map pin (checkout
 * needs the pin to check the delivery area). Orders keep their own copy
 * of the delivery address, so past orders are not affected.
 */
class AdminAddressController extends Controller
{
    public function pruneOutsideArea(): JsonResponse
    {
        if (StoreLocator::locatedStores()->isEmpty()) {
            return response()->json(['message' => 'Set a store location first — without one every address would look out of range.'], 422);
        }

        $outside = Address::query()
            ->get(['id', 'latitude', 'longitude'])
            ->filter(fn (Address $a) => $a->latitude === null || $a->longitude === null
                || StoreLocator::servingStore((float) $a->latitude, (float) $a->longitude) === null)
            ->pluck('id');

        Address::whereIn('id', $outside)->delete();

        return response()->json(['data' => [
            'deleted' => $outside->count(),
            'kept' => Address::count(),
        ]]);
    }
}
