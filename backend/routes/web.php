<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Serve the built React storefront (its files live in public/ after deploy).
// The API lives under /api/* and is handled by routes/api.php.
$spa = function (Request $request) {
    if ($request->is('api/*')) {
        abort(404);
    }

    $index = public_path('index.html');

    return file_exists($index)
        ? response()->file($index)
        : response()->view('welcome');
};

Route::get('/', $spa);
Route::fallback($spa);
