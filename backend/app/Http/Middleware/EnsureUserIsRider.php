<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsRider
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        abort_unless($user?->is_rider, 403, 'Delivery rider access required.');

        // Presence heartbeat — the rider app polls /rider/orders every 15s, so
        // this doubles as "last online". Throttled to at most one write/minute.
        if (! $user->rider_last_seen_at || $user->rider_last_seen_at->lt(now()->subSeconds(60))) {
            $user->forceFill(['rider_last_seen_at' => now()])->saveQuietly();
        }

        return $next($request);
    }
}
