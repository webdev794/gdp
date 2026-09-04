<?php

return [
    'tax_rate_bps' => (int) env('CHECKOUT_TAX_RATE_BPS', 887),
    'delivery_fee_cents' => (int) env('CHECKOUT_DELIVERY_FEE_CENTS', 599),
    'free_delivery_threshold_cents' => (int) env('CHECKOUT_FREE_DELIVERY_THRESHOLD_CENTS', 3500),

    // Reject orders whose delivery address is outside the active store's radius.
    'enforce_radius' => (bool) env('CHECKOUT_ENFORCE_RADIUS', true),
];