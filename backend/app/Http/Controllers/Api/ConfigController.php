<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class ConfigController extends Controller
{
    /**
     * Public client configuration for the web and mobile storefronts.
     */
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'data' => [
                'currency' => 'usd',
                'stripe_publishable_key' => config('services.stripe.key'),
                'payments_enabled' => (bool) config('services.stripe.secret'),
                'otp_enabled' => (bool) config('otp.enabled'),
                'tax_rate_bps' => (int) config('checkout.tax_rate_bps'),
                'delivery_fee_cents' => (int) config('checkout.delivery_fee_cents'),
                'free_delivery_threshold_cents' => (int) config('checkout.free_delivery_threshold_cents'),
            ],
        ]);
    }
}
