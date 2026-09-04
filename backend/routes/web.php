<?php

use App\Http\Controllers\SpaController;
use Illuminate\Support\Facades\Route;

// The React storefront is served from public/index.html; the API lives under
// /api/* (routes/api.php). Using a controller keeps `route:cache` working.
Route::get('/', SpaController::class);
Route::fallback(SpaController::class);
