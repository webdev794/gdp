<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Page;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AdminPageController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(['data' => Page::query()->ordered()->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $data['slug'] = $this->uniqueSlug($data['slug'] ?? null, $data['title']);

        return response()->json(['data' => Page::create($data)], 201);
    }

    public function update(Request $request, Page $page): JsonResponse
    {
        $data = $this->validated($request, $page);

        if (array_key_exists('slug', $data)) {
            $data['slug'] = $this->uniqueSlug($data['slug'] ?: null, $data['title'] ?? $page->title, $page->id);
        }

        $page->update($data);

        return response()->json(['data' => $page]);
    }

    public function destroy(Page $page): JsonResponse
    {
        $page->delete();

        return response()->json(status: 204);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request, ?Page $page = null): array
    {
        $required = $page ? 'sometimes' : 'required';

        return $request->validate([
            'title' => [$required, 'string', 'max:160'],
            'slug' => ['sometimes', 'nullable', 'string', 'max:160', 'regex:/^[a-z0-9-]+$/'],
            'content' => ['sometimes', 'nullable', 'string', 'max:60000'],
            'is_published' => ['sometimes', 'boolean'],
            'show_in_footer' => ['sometimes', 'boolean'],
            'footer_group' => ['sometimes', 'string', 'max:60'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:9999'],
        ]);
    }

    private function uniqueSlug(?string $slug, string $title, ?int $ignoreId = null): string
    {
        $base = Str::slug($slug ?: $title) ?: 'page';
        $candidate = $base;
        $suffix = 2;

        while (Page::query()->where('slug', $candidate)
            ->when($ignoreId, fn ($query) => $query->whereKeyNot($ignoreId))
            ->exists()) {
            $candidate = "{$base}-{$suffix}";
            $suffix++;
        }

        return $candidate;
    }
}
