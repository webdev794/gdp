<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Throwable;

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

        $folder = $validated['folder'] ?? 'products';
        $disk = Storage::disk('public');

        // Belt-and-braces: some hosts' Flysystem/local-adapter combination
        // doesn't reliably auto-create a missing target directory on write
        // (e.g. if a deploy shipped storage/app/public without its
        // subfolders — zip tools can silently drop empty directories). This
        // makes a missing folder self-heal instead of failing the upload.
        if (! $disk->exists($folder)) {
            $disk->makeDirectory($folder);
        }

        try {
            $path = $request->file('file')->store($folder, 'public');
        } catch (Throwable $e) {
            // A silent/generic failure here is exactly what made the last
            // round of this bug hard to diagnose from the client side — log
            // the real reason and hand the admin something actionable.
            Log::error('Media upload failed', ['folder' => $folder, 'error' => $e->getMessage()]);

            return response()->json([
                'message' => 'Could not save the uploaded file. Check that storage/app/public/'.$folder.' exists and is writable.',
            ], 500);
        }

        if (! $disk->exists($path)) {
            Log::error('Media upload reported success but file is missing', ['folder' => $folder, 'path' => $path]);

            return response()->json([
                'message' => 'The upload did not save correctly. Check storage/app/public/'.$folder.' is writable on the server.',
            ], 500);
        }

        return response()->json([
            'data' => [
                // Root-relative on purpose: an absolute URL here would bake
                // whichever APP_URL/ASSET_URL was active at upload time into
                // the database, breaking as soon as the app moves domains
                // (e.g. local dev -> production, or one prod path -> another).
                'url' => '/storage/' . $path,
                'path' => $path,
            ],
        ], 201);
    }
}
