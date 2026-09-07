<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\Order;
use App\Models\Setting;
use App\Models\Store;
use App\Support\CheckoutFees;
use App\Support\Geo;
use App\Support\Purchasable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class CheckoutController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'address_id' => ['sometimes', 'integer', 'exists:addresses,id'],
            'address.name' => ['required_without:address_id', 'string', 'max:120'],
            'address.line1' => ['required_without:address_id', 'string', 'max:255'],
            'address.line2' => ['nullable', 'string', 'max:255'],
            'address.city' => ['nullable', 'string', 'max:100'],
            'address.state' => ['nullable', 'string', 'max:60'],
            'address.postal_code' => ['nullable', 'string', 'max:12'],
            'address.latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'address.longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'delivery_instructions' => ['sometimes', 'nullable', 'string', 'max:500'],
            'payment_method' => ['sometimes', Rule::in(['card', 'cod'])],
            'phone' => ['sometimes', 'nullable', 'string', 'max:32'],
        ]);

        $paymentMethod = $validated['payment_method'] ?? 'card';

        // A phone number is optional at sign-up but required to place an order —
        // the delivery rider needs a way to reach the customer. Accept one in the
        // request (and remember it on the account) or fall back to the saved one.
        $phone = trim((string) ($validated['phone'] ?? $request->user()->phone ?? ''));

        if ($phone === '') {
            throw ValidationException::withMessages([
                'phone' => ['Add a phone number so your delivery rider can reach you.'],
            ]);
        }

        if ($request->user()->phone !== $phone) {
            $request->user()->update(['phone' => $phone]);
        }

        if ($paymentMethod === 'cod' && ! Setting::get('cod_enabled', false)) {
            throw ValidationException::withMessages([
                'payment_method' => ['Cash on delivery is not available right now.'],
            ]);
        }

        $order = DB::transaction(function () use ($request, $validated, $paymentMethod, $phone): Order {
            $address = isset($validated['address_id'])
                ? $request->user()->addresses()->findOrFail($validated['address_id'])->toArray()
                : $validated['address'];

            // Freeze the contact number onto the order snapshot so it stays put
            // even if the customer later edits their profile.
            $address['phone'] = $phone;

            $fees = CheckoutFees::current();
            $area = $this->resolveDelivery($address, $fees);
            $cart = Cart::query()->where('user_id', $request->user()->id)->first();

            if (! $cart) {
                throw ValidationException::withMessages(['cart' => ['Your cart is empty.']]);
            }

            $cart->load('items.product.category', 'items.productVariant');
            if ($cart->items->isEmpty()) {
                throw ValidationException::withMessages(['cart' => ['Your cart is empty.']]);
            }

            $subtotal = 0;
            $orderItems = [];

            foreach ($cart->items as $cartItem) {
                $product = $cartItem->product()->lockForUpdate()->first();
                $name = $product?->name ?? $cartItem->product?->name;

                if (! $product) {
                    throw ValidationException::withMessages(['cart' => ["{$name} is no longer available."]]);
                }

                $variant = $cartItem->product_variant_id
                    ? $product->variants()->whereKey($cartItem->product_variant_id)->lockForUpdate()->first()
                    : null;

                if ($cartItem->product_variant_id && ! $variant) {
                    throw ValidationException::withMessages(['cart' => ["An option for {$product->name} is no longer available."]]);
                }

                $state = Purchasable::resolve($product, $variant);

                if (! $state['active']) {
                    throw ValidationException::withMessages(['cart' => ["{$product->name} is no longer available."]]);
                }

                if ($cartItem->quantity > $state['inventory_quantity']) {
                    throw ValidationException::withMessages(['cart' => ["{$product->name} does not have enough inventory."]]);
                }

                $lineTotal = $state['price_cents'] * $cartItem->quantity;
                $subtotal += $lineTotal;
                $orderItems[] = [
                    'product_id' => $product->id,
                    'product_variant_id' => $variant?->id,
                    'product_name' => $product->name,
                    'sku' => $variant->sku ?? $product->sku,
                    'variant_label' => $state['label'],
                    'quantity' => $cartItem->quantity,
                    'unit_price_cents' => $state['price_cents'],
                    'line_total_cents' => $lineTotal,
                ];

                if ($variant) {
                    $variant->decrement('inventory_quantity', $cartItem->quantity);
                } else {
                    $product->decrement('inventory_quantity', $cartItem->quantity);
                }
            }

            $tax = (int) round($subtotal * $fees['tax_rate_bps'] / 10000);
            $deliveryFee = CheckoutFees::deliveryFeeCents($fees, $subtotal, $area['km'], $area['radius_km']);
            $handlingFee = (int) $fees['handling_fee_cents'];
            $smallCartFee = $subtotal < $fees['small_cart_min_cents']
                ? (int) $fees['small_cart_fee_cents']
                : 0;

            $order = Order::create([
                'user_id' => $request->user()->id,
                // Cash-on-delivery skips Stripe, so the order is confirmed and
                // enters the delivery pipeline immediately; cash is collected on
                // hand-off and an admin marks it paid then.
                'status' => $paymentMethod === 'cod' ? 'confirmed' : 'pending_payment',
                'payment_status' => 'pending',
                'payment_method' => $paymentMethod,
                'subtotal_cents' => $subtotal,
                'tax_cents' => $tax,
                'delivery_fee_cents' => $deliveryFee,
                'handling_fee_cents' => $handlingFee,
                'small_cart_fee_cents' => $smallCartFee,
                'total_cents' => $subtotal + $tax + $deliveryFee + $handlingFee + $smallCartFee,
                'delivery_address' => $address,
                'delivery_instructions' => $validated['delivery_instructions'] ?? null,
            ]);
            $order->items()->createMany($orderItems);
            $cart->items()->delete();

            return $order->load('items');
        });

        return response()->json(['data' => $order], 201);
    }

    /**
     * Resolve the delivery point against the active stores: reject an
     * out-of-range address when radius enforcement is on, and return the
     * nearest-store distance + radius for a distance-based delivery fee.
     *
     * @param  array<string, mixed>  $address
     * @param  array<string, int|string>  $fees
     * @return array{km: float|null, radius_km: float|null}
     */
    private function resolveDelivery(array $address, array $fees): array
    {
        $enforce = (bool) config('checkout.enforce_radius');
        $distanceMode = ($fees['delivery_mode'] ?? 'fixed') === 'distance';
        $none = ['km' => null, 'radius_km' => null];

        if (! $enforce && ! $distanceMode) {
            return $none;
        }

        $stores = Store::query()->where('is_active', true)
            ->whereNotNull('latitude')->whereNotNull('longitude')->get();

        if ($stores->isEmpty()) {
            return $none;
        }

        $lat = $address['latitude'] ?? null;
        $lng = $address['longitude'] ?? null;

        if ($lat === null || $lng === null) {
            [$lat, $lng] = Geo::geocode(implode(', ', array_filter([
                $address['line1'] ?? null,
                $address['city'] ?? null,
                $address['state'] ?? null,
                $address['postal_code'] ?? null,
            ])));
        }

        if ($lat === null || $lng === null) {
            if ($enforce) {
                throw ValidationException::withMessages([
                    'address' => ["We couldn't check delivery for that address. Set your location on the map to continue."],
                ]);
            }

            // Distance mode without coordinates: charge the far (worst-case) fee.
            return $none;
        }

        $nearest = Geo::nearestStore($stores, (float) $lat, (float) $lng);
        $km = $nearest['km'];
        $radiusKm = (float) $nearest['store']->delivery_radius_km;

        if ($enforce && $km > $radiusKm) {
            throw ValidationException::withMessages([
                'address' => ["We don't deliver to your area yet — we're expanding fast and will reach you soon."],
            ]);
        }

        return ['km' => $km, 'radius_km' => $radiusKm];
    }
}