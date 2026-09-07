<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MediaController extends Controller
{
    /**
     * Store an uploaded image on the configured public disk and return its URL.
     * The disk is swappable to S3 (or any Flysystem driver) via FILESYSTEM_DISK
     * without touching callers.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,webp,gif', 'max:4096'],
            'folder' => ['sometimes', 'string', 'in:products,categories,stores'],
        ]);

        $path = $request->file('file')->store($validated['folder'] ?? 'products', 'public');

        return response()->json([
            'data' => [
                'url' => \Illuminate\Support\Facades\Storage::disk('public')->url($path),
                'path' => $path,
            ],
        ], 201);
    }
}
