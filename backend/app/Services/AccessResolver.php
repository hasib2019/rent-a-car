<?php

namespace App\Services;

use App\Models\AppSetting;
use App\Models\Feature;
use App\Models\Package;
use App\Models\User;

/**
 * Decides what a user may use in the app.
 *
 *  - A running subscription → exactly what its package grants.
 *  - No subscription → full access, unless the admin set a fallback package
 *    under Settings → "Users without a package".
 */
class AccessResolver
{
    /**
     * @return array{mode: string, features: array<string, bool>, limits: array<string, int|null>, expires_at: string|null}
     */
    public function for(User $user): array
    {
        $allKeys = Feature::query()->orderBy('sort_order')->pluck('key')->all();
        $subscription = $user->activeSubscription()->with('package.features')->first();

        $package = $subscription?->package;
        $mode = 'package';

        if ($package === null) {
            $fallback = AppSetting::get('no_package_access', 'full');
            $package = $fallback !== 'full' ? Package::with('features')->find($fallback) : null;
            $mode = $package ? 'fallback' : 'full';
        }

        if ($package === null) {
            return [
                'mode' => 'full',
                'features' => array_fill_keys($allKeys, true),
                'limits' => ['max_vehicles' => null, 'max_drivers' => null],
                'expires_at' => null,
            ];
        }

        $granted = $package->features->pluck('key')->all();

        return [
            'mode' => $mode,
            'features' => collect($allKeys)->mapWithKeys(fn ($k) => [$k => in_array($k, $granted, true)])->all(),
            'limits' => ['max_vehicles' => $package->max_vehicles, 'max_drivers' => $package->max_drivers],
            'expires_at' => $subscription?->ends_at?->toIso8601String(),
        ];
    }
}
