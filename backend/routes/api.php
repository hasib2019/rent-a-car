<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ConfigController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ProfileController;
use Illuminate\Support\Facades\Route;

/*
| GariKhata app API — see backend/API.md for request / response examples.
*/

Route::prefix('v1')->middleware(['api.locale', 'api.maintenance'])->group(function () {
    Route::get('config', ConfigController::class);

    Route::prefix('auth')->middleware('throttle:auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
        Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('reset-password', [AuthController::class, 'resetPassword']);
    });

    Route::middleware(['auth:sanctum', 'api.active'])->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('me', [ProfileController::class, 'show']);
        Route::put('me', [ProfileController::class, 'update']);
        Route::put('me/password', [ProfileController::class, 'password']);
        Route::delete('me', [ProfileController::class, 'destroy']);
        Route::post('events', [EventController::class, 'store'])->middleware('throttle:events');
    });
});
