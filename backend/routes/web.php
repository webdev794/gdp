<?php

use App\Http\Controllers\SpaController;
use Illuminate\Support\Facades\Route;

// The React storefront is served from public/index.html; the API lives under
// /api/* (routes/api.php). Using a controller keeps `route:cache` working.
Route::get('/', SpaController::class);

// Serves files from storage/app/public without relying on `storage:link`.
// The cPanel single-folder deployment (app root == web root, see
// index.php's usePublicPath()) makes public_path('storage') resolve to the
// exact same path as storage_path() itself, so the symlink `storage:link`
// would create collides with the real storage/ directory and is silently a
// no-op — and some shared hosts disable symlink() outright anyway. Without
// this route, any /storage/... request falls through to the SPA fallback
// below and "succeeds" with the homepage's HTML instead of the image.
Route::get('/storage/{path}', function (string $path) {
    $root = storage_path('app/public');
    $file = realpath($root . '/' . $path);

    abort_unless($file && str_starts_with($file, $root . DIRECTORY_SEPARATOR) && is_file($file), 404);

    return response()->file($file, ['Cache-Control' => 'public, max-age=31536000, immutable']);
})->where('path', '.*');

Route::fallback(SpaController::class);
