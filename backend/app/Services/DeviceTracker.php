<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Http\Request;

/** Records which phone / browser a user signs in from. */
class DeviceTracker
{
    public function record(User $user, Request $request): void
    {
        $device = (array) $request->input('device', []);
        $platform = $device['platform'] ?? $request->header('X-Platform');
        $version = $device['app_version'] ?? $request->header('X-App-Version');

        $user->forceFill(array_filter([
            'last_platform' => $platform,
            'last_app_version' => $version,
            'last_seen_at' => now(),
        ]))->saveQuietly();

        $id = $device['id'] ?? $request->header('X-Device-Id');
        if (! $id) {
            return;
        }

        $user->devices()->updateOrCreate(
            ['device_id' => substr($id, 0, 100)],
            array_filter([
                'platform' => $platform,
                'model' => $device['model'] ?? null,
                'os_version' => $device['os_version'] ?? null,
                'app_version' => $version,
                'last_seen_at' => now(),
            ]),
        );
    }
}
