<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\JsonResponse;

class ConfigController extends Controller
{
    /** Public app configuration the app reads on start. */
    public function __invoke(): JsonResponse
    {
        $s = AppSetting::values();

        return response()->json(['data' => [
            'min_app_version' => $s['min_app_version'],
            'latest_app_version' => $s['latest_app_version'],
            'force_update' => (bool) $s['force_update'],
            'update_url' => $s['update_url'],
            'maintenance_mode' => (bool) $s['maintenance_mode'],
            'maintenance_message' => $s['maintenance_message'],
            'registration_open' => (bool) $s['registration_open'],
            'support' => [
                'phone' => $s['support_phone'],
                'email' => $s['support_email'],
                'whatsapp' => $s['support_whatsapp'],
            ],
        ]]);
    }
}
