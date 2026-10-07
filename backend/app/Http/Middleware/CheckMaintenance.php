<?php

namespace App\Http\Middleware;

use App\Models\AppSetting;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Lets the admin pause the API from Settings without a deploy. */
class CheckMaintenance
{
    public function handle(Request $request, Closure $next): Response
    {
        if (AppSetting::get('maintenance_mode') && ! $request->is('api/v1/config')) {
            return response()->json([
                'code' => 'maintenance',
                'message' => AppSetting::get('maintenance_message') ?: __('api.maintenance'),
            ], 503);
        }

        return $next($request);
    }
}
