<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsRider
{
    public function handle(Request $request, Closure $next): Response
    {
        abort_unless($request->user()?->is_rider, 403, 'Delivery rider access required.');

        return $next($request);
    }
}
