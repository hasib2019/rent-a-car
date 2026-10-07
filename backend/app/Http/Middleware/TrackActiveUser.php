<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Blocks suspended accounts and records when / from where a user was last seen.
 */
class TrackActiveUser
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && ! $user->isActive()) {
            $user->currentAccessToken()?->delete();

            return response()->json(['code' => 'account_suspended', 'message' => __('api.suspended')], 403);
        }

        if ($user && ($user->last_seen_at === null || $user->last_seen_at->lt(now()->subMinutes(5)))) {
            $user->forceFill(array_filter([
                'last_seen_at' => now(),
                'last_platform' => $request->header('X-Platform'),
                'last_app_version' => $request->header('X-App-Version'),
            ]))->saveQuietly();
        }

        return $next($request);
    }
}
