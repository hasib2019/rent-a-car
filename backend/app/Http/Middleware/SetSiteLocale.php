<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Public website language: Bangla by default, remembered in the session. */
class SetSiteLocale
{
    public function handle(Request $request, Closure $next): Response
    {
        app()->setLocale($request->session()->get('site_locale', 'bn'));

        return $next($request);
    }
}
