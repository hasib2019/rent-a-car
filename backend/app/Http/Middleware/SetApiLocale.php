<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Answers in Bangla when the app asks for it (Accept-Language: bn). */
class SetApiLocale
{
    public function handle(Request $request, Closure $next): Response
    {
        $lang = substr((string) $request->header('Accept-Language', 'en'), 0, 2);
        app()->setLocale($lang === 'bn' ? 'bn' : 'en');

        return $next($request);
    }
}
