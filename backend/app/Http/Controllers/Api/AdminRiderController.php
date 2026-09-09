<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\Geo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AdminRiderController extends Controller
{
    public function index(): JsonResponse
    {
        $riders = User::query()
            ->where('is_rider', true)
            ->with('stores:id,name,city')
            ->withCount(['deliveries as active_deliveries' => fn ($query) => $query
                ->whereIn('status', ['ready_for_delivery', 'out_for_delivery'])])
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $riders->map($this->row(...))->values()]);
    }

    /**
     * Promote an existing account to a delivery rider, by email.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email', 'max:255'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user) {
            throw ValidationException::withMessages(['email' => ['No account with that email.']]);
        }

        if ($user->is_admin) {
            throw ValidationException::withMessages(['email' => ['That account is an administrator.']]);
        }

        $user->forceFill(['is_rider' => true, 'rider_is_active' => true])->save();

        return response()->json(['data' => $this->row($user->fresh()->load('stores:id,name,city'))], 201);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        abort_unless($user->is_rider, 404);

        $data = $request->validate([
            'phone' => ['sometimes', 'nullable', 'string', 'max:32'],
            'rider_is_active' => ['sometimes', 'boolean'],
            'rider_base_address' => ['sometimes', 'nullable', 'string', 'max:255'],
            'rider_base_lat' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'rider_base_lng' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'store_ids' => ['sometimes', 'array'],
            'store_ids.*' => ['integer', 'exists:stores,id'],
        ]);

        $attributes = collect($data)->only([
            'phone', 'rider_is_active', 'rider_base_address', 'rider_base_lat', 'rider_base_lng',
        ])->all();

        // Geocode the base address when coordinates weren't supplied with it.
        if (array_key_exists('rider_base_address', $attributes)
            && ! empty($attributes['rider_base_address'])
            && empty($data['rider_base_lat'])
            && empty($data['rider_base_lng'])) {
            [$lat, $lng] = Geo::geocode($attributes['rider_base_address']);
            $attributes['rider_base_lat'] = $lat;
            $attributes['rider_base_lng'] = $lng;
        }

        if ($attributes) {
            $user->forceFill($attributes)->save();
        }

        if (array_key_exists('store_ids', $data)) {
            $user->stores()->sync($data['store_ids']);
        }

        return response()->json(['data' => $this->row(
            $user->fresh()->load('stores:id,name,city')->loadCount(['deliveries as active_deliveries' => fn ($query) => $query
                ->whereIn('status', ['ready_for_delivery', 'out_for_delivery'])])
        )]);
    }

    /**
     * Drop the rider role. The account stays; it just can't deliver any more.
     */
    public function destroy(User $user): JsonResponse
    {
        abort_unless($user->is_rider, 404);

        $user->stores()->detach();
        $user->forceFill(['is_rider' => false, 'rider_is_active' => false])->save();

        return response()->json(status: 204);
    }

    /**
     * @return array<string, mixed>
     */
    private function row(User $rider): array
    {
        $location = $rider->riderLocation();

        return [
            'id' => $rider->id,
            'name' => $rider->name,
            'email' => $rider->email,
            'phone' => $rider->phone,
            'rider_is_active' => (bool) $rider->rider_is_active,
            'rider_base_address' => $rider->rider_base_address,
            'rider_base_lat' => $rider->rider_base_lat,
            'rider_base_lng' => $rider->rider_base_lng,
            'located' => $location ? [
                'lat' => $location['lat'],
                'lng' => $location['lng'],
                'source' => $location['source'],
                'last_ping_at' => $rider->rider_last_located_at,
            ] : null,
            'active_deliveries' => (int) ($rider->active_deliveries ?? 0),
            'stores' => $rider->relationLoaded('stores')
                ? $rider->stores->map(fn ($s) => ['id' => $s->id, 'name' => $s->name, 'city' => $s->city])->values()
                : [],
        ];
    }
}
