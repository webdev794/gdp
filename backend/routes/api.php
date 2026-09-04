<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AddressController;
use App\Http\Controllers\Api\AdminCategoryController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AdminOrderController;
use App\Http\Controllers\Api\AdminProductController;
use App\Http\Controllers\Api\AdminStoreController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\ConfigController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PaymentController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::middleware('throttle:12,1')->group(function () {
    Route::post('/auth/start', [AuthController::class, 'start']);
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('/auth/resend-otp', [AuthController::class, 'resendOtp']);
});

Route::get('/config', ConfigController::class);
Route::get('/delivery-eta', DeliveryController::class);

Route::get('/categories', [CatalogController::class, 'categories']);
Route::get('/products', [CatalogController::class, 'products']);
Route::get('/products/{product:slug}', [CatalogController::class, 'product']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/addresses', [AddressController::class, 'index']);
    Route::post('/addresses', [AddressController::class, 'store']);
    Route::get('/cart', [CartController::class, 'show']);
    Route::post('/cart/items', [CartController::class, 'addItem']);
    Route::patch('/cart/items/{cartItem}', [CartController::class, 'updateItem']);
    Route::delete('/cart/items/{cartItem}', [CartController::class, 'removeItem']);
    Route::delete('/cart', [CartController::class, 'clear']);
    Route::post('/checkout', [CheckoutController::class, 'store']);
    Route::get('/orders', [OrderController::class, 'index']);
    Route::get('/orders/{order}', [OrderController::class, 'show']);
    Route::post('/orders/{order}/payment-intent', [PaymentController::class, 'intent']);
});

Route::middleware(['auth:sanctum', 'admin'])->prefix('admin')->group(function () {
    Route::get('/metrics', [AdminController::class, 'metrics']);
    Route::get('/customers', [AdminController::class, 'customers']);
    Route::get('/customers/{user}', [AdminController::class, 'customer']);
    Route::get('/orders', [AdminOrderController::class, 'index']);
    Route::get('/orders/{order}', [AdminOrderController::class, 'show']);
    Route::patch('/orders/{order}', [AdminOrderController::class, 'update']);

    Route::get('/products', [AdminProductController::class, 'index']);
    Route::post('/products', [AdminProductController::class, 'store']);
    Route::patch('/products/{product}', [AdminProductController::class, 'update']);
    Route::delete('/products/{product}', [AdminProductController::class, 'destroy']);

    Route::get('/stores', [AdminStoreController::class, 'index']);
    Route::post('/stores', [AdminStoreController::class, 'store']);
    Route::patch('/stores/{store}', [AdminStoreController::class, 'update']);
    Route::delete('/stores/{store}', [AdminStoreController::class, 'destroy']);

    Route::get('/categories', [AdminCategoryController::class, 'index']);
    Route::post('/categories', [AdminCategoryController::class, 'store']);
    Route::patch('/categories/{category}', [AdminCategoryController::class, 'update']);
    Route::delete('/categories/{category}', [AdminCategoryController::class, 'destroy']);
});

Route::post('/payments/stripe/webhook', [PaymentController::class, 'webhook']);

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/auth/logout', [AuthController::class, 'logout'])
    ->middleware('auth:sanctum');
