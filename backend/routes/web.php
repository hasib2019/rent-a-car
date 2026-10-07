<?php

use App\Http\Controllers\Site\AdminLoginController;
use App\Http\Controllers\Site\SiteController;
use Illuminate\Support\Facades\Route;

Route::middleware('site.locale')->group(function () {
    Route::get('/', [SiteController::class, 'home'])->name('home');
    Route::get('/privacy', [SiteController::class, 'privacy'])->name('privacy');
    Route::get('/account-deletion', [SiteController::class, 'deletion'])->name('deletion');
    Route::get('/download/android', [SiteController::class, 'download'])->name('download.android');
    Route::get('/lang/{locale}', [SiteController::class, 'locale'])->whereIn('locale', ['bn', 'en'])->name('lang');

    Route::get('/login', [AdminLoginController::class, 'show'])->name('login');
    Route::post('/login', [AdminLoginController::class, 'login'])->name('login.attempt');
    Route::post('/logout', [AdminLoginController::class, 'logout'])->name('logout');
});

// Short link.
Route::redirect('/l', '/login');
