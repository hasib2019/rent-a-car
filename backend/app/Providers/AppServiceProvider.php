<?php

namespace App\Providers;

use Illuminate\Auth\Events\Login;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(
            \Filament\Auth\Http\Responses\Contracts\LogoutResponse::class,
            \App\Http\Responses\AdminLogoutResponse::class,
        );
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Login / register / password reset: per IP and per identifier.
        RateLimiter::for('auth', fn (Request $request) => [
            Limit::perMinute(20)->by($request->ip()),
            Limit::perMinute(6)->by(strtolower((string) ($request->input('login') ?? $request->input('email'))).'|'.$request->ip()),
        ]);

        Event::listen(Login::class, function (Login $event) {
            if ($event->guard === 'admin') {
                $event->user->forceFill(['last_login_at' => now()])->saveQuietly();
            }
        });

        RateLimiter::for('events', fn (Request $request) => Limit::perMinute(60)->by($request->user()?->id ?: $request->ip()));
    }
}
