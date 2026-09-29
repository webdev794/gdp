<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * Product ratings shared by the website and the mobile apps. Anyone can read a
 * product's visible reviews. Reviews are written from an order: each product on
 * a confirmed order (not awaiting payment or cancelled) can be rated once.
 */
class ProductReviewController extends Controller
{
    public function index(Product $product): JsonResponse
    {
        $reviews = $product->reviews()
            ->where('is_hidden', false)
            ->with('customer:id,name')
            ->latest()
            ->limit(50)
            ->get();

        return response()->json([
            'data' => $reviews->map->toPublicArray()->values(),
            'summary' => [
                'average' => $product->rating_avg,
                'count' => $product->rating_count,
            ],
        ]);
    }

    public function store(Request $request, Order $order): JsonResponse
    {
        abort_unless($order->user_id === $request->user()->id, 404);

        $validated = $request->validate([
            'product_id' => ['required', 'integer'],
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);

        if (in_array($order->status, ['pending_payment', 'cancelled'], true)) {
            throw ValidationException::withMessages([
                'rating' => ['You can review items once the order is confirmed.'],
            ]);
        }

        $productId = (int) $validated['product_id'];
        if (! $order->items()->where('product_id', $productId)->exists()) {
            throw ValidationException::withMessages(['product_id' => ['That product is not on this order.']]);
        }

        if ($order->productReviews()->where('product_id', $productId)->exists()) {
            throw ValidationException::withMessages(['rating' => ['You have already reviewed this item for this order.']]);
        }

        $review = ProductReview::create([
            'order_id' => $order->id,
            'product_id' => $productId,
            'user_id' => $request->user()->id,
            'rating' => $validated['rating'],
            'comment' => trim((string) ($validated['comment'] ?? '')) ?: null,
        ]);
        $review->product?->refreshRating();

        return response()->json(['data' => $review->load('customer:id,name')->toPublicArray()], 201);
    }
}
