<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

/**
 * Simple key/value store for settings the admin can change at runtime.
 */
#[Fillable(['key', 'value'])]
class AppSetting extends Model
{
    protected $primaryKey = 'key';

    public $incrementing = false;

    protected $keyType = 'string';

    /** Defaults used until the admin saves something. */
    public const DEFAULTS = [
        'support_phone' => '',
        'support_email' => '',
        'support_whatsapp' => '',
        'min_app_version' => '1.0.0',
        'latest_app_version' => '1.0.0',
        'update_url' => '',
        'force_update' => false,
        'maintenance_mode' => false,
        'maintenance_message' => '',
        'registration_open' => true,
        // What users without a running package get: "full" or a package id.
        'no_package_access' => 'full',
    ];

    public static function values(): array
    {
        return Cache::rememberForever('app_settings', function () {
            $stored = static::query()->pluck('value', 'key')->map(fn ($v) => json_decode($v, true))->all();

            return array_merge(self::DEFAULTS, $stored);
        });
    }

    public static function get(string $key, mixed $default = null): mixed
    {
        return static::values()[$key] ?? $default;
    }

    public static function put(array $values): void
    {
        foreach ($values as $key => $value) {
            static::query()->updateOrCreate(['key' => $key], ['value' => json_encode($value)]);
        }
        Cache::forget('app_settings');
    }
}
