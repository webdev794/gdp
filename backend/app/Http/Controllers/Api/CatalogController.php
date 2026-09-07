<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public function categories(): JsonResponse
    {
        return response()->json([
            'data' => Category::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function products(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category' => ['sometimes', 'string', 'exists:categories,slug'],
            'search' => ['sometimes', 'string', 'min:2', 'max:100'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:50'],
        ]);

        $products = Product::query()
            ->with(['category', 'variants' => fn ($query) => $query->where('is_active', true)])
            ->where('is_active', true)
            ->whereHas('category', fn ($query) => $query->where('is_active', true))
            ->when(isset($validated['search']), function ($query) use ($validated) {
                $search = $validated['search'];

                $query->where(function ($searchQuery) use ($search) {
                    $searchQuery
                        ->where('name', 'like', "%{$search}%")
                        ->orWhere('description', 'like', "%{$search}%")
                        ->orWhere('sku', 'like', "%{$search}%")
                        ->orWhereHas('variants', fn ($variantQuery) => $variantQuery
                            ->where('label', 'like', "%{$search}%")
                            ->orWhere('sku', 'like', "%{$search}%"));
                });
            })
            ->when(isset($validated['category']), fn ($query) => $query->whereHas(
                'category',
                fn ($categoryQuery) => $categoryQuery->where('slug', $validated['category'])
            ))
            ->orderBy('name')
            ->paginate($validated['per_page'] ?? 20)
            ->through(fn (Product $product) => $this->withPricing($product));

        return response()->json($products);
    }

    public function product(Product $product): JsonResponse
    {
        abort_unless(
            $product->is_active && $product->category?->is_active,
            404
        );

        $product->load(['category', 'variants' => fn ($query) => $query->where('is_active', true)]);

        return response()->json([
            'data' => $this->withPricing($product),
        ]);
    }

    /**
     * Attach the price range across active variants (or the product price when
     * there are none) so the storefront can show "from $x".
     */
    private function withPricing(Product $product): Product
    {
        // The base product is always a selectable option, so its price counts
        // toward the range too.
        $prices = $product->variants->pluck('price_cents')->push($product->price_cents);

        $product->setAttribute('price_min_cents', (int) $prices->min());
        $product->setAttribute('price_max_cents', (int) $prices->max());

        return $product;
    }
}
