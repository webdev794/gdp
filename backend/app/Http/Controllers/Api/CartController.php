<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CartController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $cart = $this->cartFor($request);

        return response()->json($this->payload($cart));
    }

    public function addItem(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'product_id' => ['required', 'integer', 'exists:products,id'],
            'quantity' => ['required', 'integer', 'min:1', 'max:1000'],
        ]);

        $cart = $this->cartFor($request);

        DB::transaction(function () use ($cart, $validated): void {
            $product = Product::query()
                ->whereKey($validated['product_id'])
                ->lockForUpdate()
                ->firstOrFail();

            $this->ensurePurchasable($product);

            $item = $cart->items()
                ->where('product_id', $product->id)
                ->lockForUpdate()
                ->first();
            $quantity = ($item?->quantity ?? 0) + $validated['quantity'];

            $this->ensureStock($product, $quantity);

            $cart->items()->updateOrCreate(
                ['product_id' => $product->id],
                [
                    'quantity' => $quantity,
                    'unit_price_cents' => $product->price_cents,
                ]
            );
        });

        return response()->json($this->payload($cart->fresh()), 201);
    }

    public function updateItem(Request $request, CartItem $cartItem): JsonResponse
    {
        $validated = $request->validate([
            'quantity' => ['required', 'integer', 'min:1', 'max:1000'],
        ]);

        $cart = $this->cartFor($request);
        abort_unless($cartItem->cart_id === $cart->id, 404);

        DB::transaction(function () use ($cartItem, $validated): void {
            $product = Product::query()
                ->whereKey($cartItem->product_id)
                ->lockForUpdate()
                ->firstOrFail();

            $this->ensurePurchasable($product);
            $this->ensureStock($product, $validated['quantity']);

            $cartItem->update([
                'quantity' => $validated['quantity'],
                'unit_price_cents' => $product->price_cents,
            ]);
        });

        return response()->json($this->payload($cart->fresh()), 200);
    }

    public function removeItem(Request $request, CartItem $cartItem): JsonResponse
    {
        $cart = $this->cartFor($request);
        abort_unless($cartItem->cart_id === $cart->id, 404);

        $cartItem->delete();

        return response()->json($this->payload($cart->fresh()), 200);
    }

    public function clear(Request $request): JsonResponse
    {
        $cart = $this->cartFor($request);
        $cart->items()->delete();

        return response()->json($this->payload($cart->fresh()), 200);
    }

    private function cartFor(Request $request): Cart
    {
        return Cart::firstOrCreate(['user_id' => $request->user()->id]);
    }

    private function payload(Cart $cart): array
    {
        $cart->load('items.product.category');
        $items = $cart->items->map(function (CartItem $item): array {
            return [
                'id' => $item->id,
                'quantity' => $item->quantity,
                'unit_price_cents' => $item->unit_price_cents,
                'line_total_cents' => $item->quantity * $item->unit_price_cents,
                'product' => $item->product,
            ];
        })->values();

        return [
            'data' => [
                'id' => $cart->id,
                'items' => $items,
                'item_count' => $items->sum('quantity'),
                'subtotal_cents' => $items->sum('line_total_cents'),
            ],
        ];
    }

    private function ensurePurchasable(Product $product): void
    {
        if (! $product->is_active || ! $product->category?->is_active) {
            throw ValidationException::withMessages([
                'product_id' => ['This product is not available.'],
            ]);
        }
    }

    private function ensureStock(Product $product, int $quantity): void
    {
        if ($quantity > $product->inventory_quantity) {
            throw ValidationException::withMessages([
                'quantity' => ['The requested quantity is not available.'],
            ]);
        }
    }
}