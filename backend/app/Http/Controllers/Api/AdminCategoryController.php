<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminCategoryController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'data' => Category::query()
                ->withCount('products')
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $data['slug'] ??= $this->uniqueSlug($data['name']);
        $position = $data['sort_order'] ?? null;
        $category = Category::create($data);
        $this->placeAt($category, $position); // no number = goes to the end

        return response()->json(['data' => $category->fresh()], 201);
    }

    public function update(Request $request, Category $category): JsonResponse
    {
        $data = $this->validated($request, $category);
        $category->update($data);
        if (array_key_exists('sort_order', $data)) {
            $this->placeAt($category, (int) $data['sort_order']);
        }

        return response()->json(['data' => $category->fresh()->loadCount('products')]);
    }

    /**
     * Put a category at a 1-based position (null = last) and renumber all
     * categories 1, 2, 3 … — a typed Sort number never creates duplicates or gaps.
     */
    private function placeAt(Category $category, ?int $position): void
    {
        $ids = Category::query()->whereKeyNot($category->id)->orderBy('sort_order')->orderBy('name')->pluck('id')->all();
        $index = $position === null ? count($ids) : max(0, min(count($ids), $position - 1));
        array_splice($ids, $index, 0, [$category->id]);
        $this->renumber($ids);
    }

    /** @param  array<int, int>  $ids */
    private function renumber(array $ids): void
    {
        DB::transaction(function () use ($ids): void {
            foreach (array_values($ids) as $index => $id) {
                Category::whereKey($id)->update(['sort_order' => $index + 1]);
            }
        });
    }

    /**
     * Drag-and-drop reorder: the full list of category ids in their new order.
     * Renumbers sort_order 1, 2, 3 … so every category keeps a unique position.
     */
    public function reorder(Request $request): JsonResponse
    {
        $ids = $request->validate([
            'ids' => ['required', 'array', 'min:1'],
            'ids.*' => ['integer', 'distinct', 'exists:categories,id'],
        ])['ids'];

        $this->renumber($ids);

        return $this->index();
    }

    public function destroy(Category $category): JsonResponse
    {
        if ($category->products()->exists()) {
            return response()->json([
                'message' => 'Move or remove this category\'s products before deleting it.',
            ], 409);
        }

        try {
            $category->delete();
            $this->renumber(Category::orderBy('sort_order')->orderBy('name')->pluck('id')->all());
        } catch (QueryException) {
            return response()->json(['message' => 'This category is still in use.'], 409);
        }

        return response()->json(status: 204);
    }

    private function validated(Request $request, ?Category $category = null): array
    {
        return $request->validate([
            'name' => [$category ? 'sometimes' : 'required', 'string', 'max:120'],
            'slug' => ['sometimes', 'nullable', 'string', 'max:140', 'alpha_dash', Rule::unique('categories')->ignore($category?->id)],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'image_url' => ['sometimes', 'nullable', 'string', 'max:500'],
            'is_active' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
        ]);
    }

    private function uniqueSlug(string $name): string
    {
        $base = Str::slug($name);
        $slug = $base;
        $suffix = 2;

        while (Category::where('slug', $slug)->exists()) {
            $slug = "{$base}-{$suffix}";
            $suffix++;
        }

        return $slug;
    }
}
