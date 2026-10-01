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
        match ($request->input('status')) {
            'pending' => $query->whereNull('approved_at')->where('is_hidden', false),
            'visible' => $query->visible(),
            'hidden' => $query->where('is_hidden', true),
            default => null,
        };

        $reviews = $query->paginate(50);

        return response()->json([
            'data' => $reviews->items(),
            'meta' => ['pending' => ProductReview::whereNull('approved_at')->where('is_hidden', false)->count(), 'total' => $reviews->total(), 'current_page' => $reviews->currentPage(), 'last_page' => $reviews->lastPage()],
        ]);
    }

    public function update(Request $request, ProductReview $review): JsonResponse
    {
        $validated = $request->validate([
            'is_hidden' => ['sometimes', 'boolean'],
            'approved' => ['sometimes', 'accepted'],
        ]);

        if ($validated['approved'] ?? false) {
            // Approve = publish on the website and in the apps.
            $review->update(['approved_at' => now(), 'is_hidden' => false]);
        } elseif (array_key_exists('is_hidden', $validated)) {
            $review->update(['is_hidden' => $validated['is_hidden']]);
        } else {
            return response()->json(['message' => 'Nothing to change.'], 422);
        }
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
