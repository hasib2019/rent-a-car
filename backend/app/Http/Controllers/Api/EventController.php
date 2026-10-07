<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ScreenView;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class EventController extends Controller
{
    /** Batched screen views sent by the app. */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'events' => ['required', 'array', 'max:100'],
            'events.*.screen' => ['required', 'string', 'max:80', 'regex:/^[a-z0-9_]+$/'],
            'events.*.viewed_at' => ['nullable', 'date'],
            'events.*.session_id' => ['nullable', 'string', 'max:64'],
        ]);

        $user = $request->user();
        $platform = substr((string) $request->header('X-Platform'), 0, 20) ?: null;
        $version = substr((string) $request->header('X-App-Version'), 0, 20) ?: null;
        $now = now();

        $rows = collect($data['events'])->map(function (array $e) use ($user, $platform, $version, $now) {
            $at = isset($e['viewed_at']) ? Carbon::parse($e['viewed_at'])->setTimezone(config('app.timezone')) : $now;
            // Clamp clocks that are wildly off.
            if ($at->gt($now->copy()->addMinutes(5)) || $at->lt($now->copy()->subDays(30))) {
                $at = $now;
            }

            return [
                'user_id' => $user->id,
                'screen' => $e['screen'],
                'session_id' => $e['session_id'] ?? null,
                'platform' => $platform,
                'app_version' => $version,
                'viewed_at' => $at,
                'created_at' => $now,
            ];
        });

        ScreenView::insert($rows->all());

        return response()->json(['accepted' => $rows->count()], 202);
    }
}
