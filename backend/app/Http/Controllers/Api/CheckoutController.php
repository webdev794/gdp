<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\Order;
use App\Models\Address;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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
            'address.city' => ['required_without:address_id', 'string', 'max:100'],
            'address.state' => ['required_without:address_id', 'string', 'max:60'],
            'address.postal_code' => ['required_without:address_id', 'string', 'max:12'],
        ]);

        $order = DB::transaction(function () use ($request, $validated): Order {
            $address = isset($validated['address_id'])
                ? $request->user()->addresses()->findOrFail($validated['address_id'])->toArray()
                : $validated['address'];
            $cart = Cart::query()->where('user_id', $request->user()->id)->first();

            if (! $cart) {
                throw ValidationException::withMessages(['cart' => ['Your cart is empty.']]);
            }

            $cart->load('items.product.category');
            if ($cart->items->isEmpty()) {
                throw ValidationException::withMessages(['cart' => ['Your cart is empty.']]);
            }

            $subtotal = 0;
            $orderItems = [];

            foreach ($cart->items as $cartItem) {
                $product = $cartItem->product()->lockForUpdate()->first();

                if (! $product || ! $product->is_active || ! $product->category?->is_active) {
                    throw ValidationException::withMessages(['cart' => ["{$cartItem->product->name} is no longer available."]]);
                }

                if ($cartItem->quantity > $product->inventory_quantity) {
                    throw ValidationException::withMessages(['cart' => ["{$product->name} does not have enough inventory."]]);
                }

                $lineTotal = $product->price_cents * $cartItem->quantity;
                $subtotal += $lineTotal;
                $orderItems[] = [
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'sku' => $product->sku,
                    'quantity' => $cartItem->quantity,
                    'unit_price_cents' => $product->price_cents,
                    'line_total_cents' => $lineTotal,
                ];

                $product->decrement('inventory_quantity', $cartItem->quantity);
            }

            $tax = (int) round($subtotal * config('checkout.tax_rate_bps') / 10000);
            $deliveryFee = $subtotal >= config('checkout.free_delivery_threshold_cents')
                ? 0
                : config('checkout.delivery_fee_cents');

            $order = Order::create([
                'user_id' => $request->user()->id,
                'status' => 'pending_payment',
                'payment_status' => 'pending',
                'subtotal_cents' => $subtotal,
                'tax_cents' => $tax,
                'delivery_fee_cents' => $deliveryFee,
                'total_cents' => $subtotal + $tax + $deliveryFee,
                'delivery_address' => $address,
            ]);
            $order->items()->createMany($orderItems);
            $cart->items()->delete();

            return $order->load('items');
        });

        return response()->json(['data' => $order], 201);
    }
}