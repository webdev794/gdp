<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProductReview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Admin moderation of product reviews: list, hide/show, delete. */
class AdminProductReviewController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = ProductReview::with(['product:id,name,slug', 'customer:id,name,email'])->latest();

        if ($request->filled('rating')) {
            $query->where('rating', (int) $request->input('rating'));
        }
        if ($request->input('status') === 'hidden') {
            $query->where('is_hidden', true);
        } elseif ($request->input('status') === 'visible') {
            $query->where('is_hidden', false);
        }

        $reviews = $query->paginate(50);

        return response()->json([
            'data' => $reviews->items(),
            'meta' => ['total' => $reviews->total(), 'current_page' => $reviews->currentPage(), 'last_page' => $reviews->lastPage()],
        ]);
    }

    public function update(Request $request, ProductReview $review): JsonResponse
    {
        $validated = $request->validate(['is_hidden' => ['required', 'boolean']]);

        $review->update($validated);
        $review->product?->refreshRating();

        return response()->json(['data' => $review->load(['product:id,name,slug', 'customer:id,name,email'])]);
    }

    public function destroy(ProductReview $review): JsonResponse
    {
        $product = $review->product;
        $review->delete();
        $product?->refreshRating();

        return response()->json(['message' => 'Review deleted.']);
    }
}
