<?php

namespace App\Support;

/**
 * Map legacy /storage/... paths to /api/media/file/... so every browser
 * (including private windows) loads uploads through Laravel. Disk layout is
 * unchanged: storage/app/public/{folder}/...
 */
class PublicMedia
{
    public static function url(?string $value): ?string
    {
        if ($value === null || $value === '') {
            return $value;
        }

        // Already on the working API stream.
        if (str_contains($value, '/api/media/file/')) {
            // Ensure root-relative form for the frontend base-path prefixer.
            if (preg_match('#/api/media/file/(.+)$#', $value, $m)) {
                return '/api/media/file/'.$m[1];
            }

            return $value;
        }

        // /storage/products/x.png, /storage/app/public/products/x.png, or a
        // full absolute URL baked in before this fix existed (e.g.
        // https://host/gdp/storage/products/x.png) — match the /storage/
        // segment wherever it falls, not just at the very start of the value.
        if (preg_match('~/storage/(?:app/public/)?([^?#]+)~', $value, $m)) {
            return '/api/media/file/'.$m[1];
        }

        return $value;
    }
}
