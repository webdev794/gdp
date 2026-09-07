<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => ['sometimes', 'string', 'max:100'],
            'category_id' => ['sometimes', 'integer', 'exists:categories,id'],
        ]);

        $products = Product::query()
            ->with(['category:id,name', 'variants'])
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(
                fn ($inner) => $inner->where('name', 'like', "%{$search}%")->orWhere('sku', 'like', "%{$search}%")
            ))
            ->when($validated['category_id'] ?? null, fn ($query, $id) => $query->where('category_id', $id))
            ->orderBy('name')
            ->paginate(30);

        return response()->json([
            'data' => $products->items(),
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'total' => $products->total(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $variants = $this->pullVariants($data);
        $data['slug'] ??= $this->uniqueSlug($data['name']);

        $product = DB::transaction(function () use ($data, $variants): Product {
            $product = Product::create($data);
            $this->syncVariants($product, $variants);

            return $product;
        });

        return response()->json(['data' => $product->load('category:id,name', 'variants')], 201);
    }

    public function update(Request $request, Product $product): JsonResponse
    {
        $data = $this->validated($request, $product);
        $variants = $this->pullVariants($data);

        DB::transaction(function () use ($product, $data, $variants): void {
            $product->update($data);
            $this->syncVariants($product, $variants);
        });

        return response()->json(['data' => $product->fresh()->load('category:id,name', 'variants')]);
    }

    public function destroy(Product $product): JsonResponse
    {
        try {
            $product->delete();
        } catch (QueryException) {
            return response()->json([
                'message' => 'This product belongs to existing orders. Deactivate it instead of deleting.',
            ], 409);
        }

        return response()->json(status: 204);
    }

    private function validated(Request $request, ?Product $product = null): array
    {
        $unique = Rule::unique('products')->ignore($product?->id);

        return $request->validate([
            'category_id' => [$product ? 'sometimes' : 'required', 'integer', 'exists:categories,id'],
            'name' => [$product ? 'sometimes' : 'required', 'string', 'max:160'],
            'slug' => ['sometimes', 'nullable', 'string', 'max:180', 'alpha_dash', $unique],
            'description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'sku' => [$product ? 'sometimes' : 'required', 'string', 'max:60', $unique],
            'price_cents' => [$product ? 'sometimes' : 'required', 'integer', 'min:0'],
            'inventory_quantity' => ['sometimes', 'integer', 'min:0'],
            'image_url' => ['sometimes', 'nullable', 'url', 'max:500'],
            'is_active' => ['sometimes', 'boolean'],

            'variants' => ['sometimes', 'array'],
            'variants.*.id' => ['sometimes', 'nullable', 'integer'],
            'variants.*._delete' => ['sometimes', 'boolean'],
            'variants.*.label' => ['required_with:variants', 'string', 'max:80'],
            'variants.*.sku' => ['required_with:variants', 'string', 'max:60'],
            'variants.*.price_cents' => ['required_with:variants', 'integer', 'min:0'],
            'variants.*.inventory_quantity' => ['sometimes', 'integer', 'min:0'],
            'variants.*.image_url' => ['sometimes', 'nullable', 'url', 'max:500'],
            'variants.*.sort_order' => ['sometimes', 'integer', 'min:0'],
            'variants.*.is_active' => ['sometimes', 'boolean'],
        ]);
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<int, array<string, mixed>>|null
     */
    private function pullVariants(array &$data): ?array
    {
        if (! array_key_exists('variants', $data)) {
            return null;
        }

        $variants = $data['variants'];
        unset($data['variants']);

        return $variants;
    }

    /**
     * @param  array<int, array<string, mixed>>|null  $rows
     */
    private function syncVariants(Product $product, ?array $rows): void
    {
        if ($rows === null) {
            return;
        }

        foreach ($rows as $index => $row) {
            $existing = ! empty($row['id'])
                ? $product->variants()->whereKey($row['id'])->first()
                : null;

            if (! empty($row['_delete'])) {
                if ($existing) {
                    try {
                        $existing->delete();
                    } catch (QueryException) {
                        abort(422, "\"{$existing->label}\" is on an existing order — deactivate it instead of deleting.");
                    }
                }

                continue;
            }

            $skuOwner = ProductVariant::where('sku', $row['sku'])->first();
            if ($skuOwner && $skuOwner->id !== ($existing->id ?? null)) {
                abort(422, "The variant SKU \"{$row['sku']}\" is already in use.");
            }

            $attributes = [
                'label' => $row['label'],
                'sku' => $row['sku'],
                'price_cents' => (int) $row['price_cents'],
                'inventory_quantity' => (int) ($row['inventory_quantity'] ?? 0),
                'image_url' => $row['image_url'] ?? null,
                'sort_order' => (int) ($row['sort_order'] ?? $index),
                'is_active' => (bool) ($row['is_active'] ?? true),
            ];

            if ($existing) {
                $existing->update($attributes);
            } else {
                $product->variants()->create($attributes);
            }
        }
    }

    private function uniqueSlug(string $name): string
    {
        $base = Str::slug($name);
        $slug = $base;
        $suffix = 2;

        while (Product::where('slug', $slug)->exists()) {
            $slug = "{$base}-{$suffix}";
            $suffix++;
        }

        return $slug;
    }
}
