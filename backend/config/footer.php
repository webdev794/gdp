<?php

/*
 * Storefront footer defaults. An administrator overrides these under
 * Admin console -> Pages -> Footer (stored in the `settings` table under the
 * `footer` key). App\Support\FooterConfig merges + normalises; GET /api/config
 * exposes the effective values.
 */

return [
    // "{year}" is replaced with the current year by the storefront.
    'copyright' => env('FOOTER_COPYRIGHT', '© {year} Grocerly'),
    'note' => env('FOOTER_NOTE', 'Grocerly is a demo storefront. Prices, delivery estimates and content pages are illustrative and set by the store operator in the admin console.'),

    'app_store_url' => env('FOOTER_APP_STORE_URL', ''),
    'play_store_url' => env('FOOTER_PLAY_STORE_URL', ''),

    // Only the platforms in this list are rendered; a blank url hides that icon.
    'socials' => [
        'facebook' => env('FOOTER_FACEBOOK_URL', ''),
        'x' => env('FOOTER_X_URL', ''),
        'instagram' => env('FOOTER_INSTAGRAM_URL', ''),
        'linkedin' => env('FOOTER_LINKEDIN_URL', ''),
        'youtube' => env('FOOTER_YOUTUBE_URL', ''),
    ],

    // Extra footer links (label + url), shown under "Useful Links" after the pages.
    'links' => [],
];
