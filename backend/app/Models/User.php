<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * An owner who uses the mobile / web app.
 */
#[Fillable([
    'name', 'username', 'email', 'phone', 'business_name', 'district', 'fleet_size',
    'status', 'password', 'signup_platform', 'last_platform', 'last_app_version',
    'last_login_at', 'last_seen_at', 'admin_note',
])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    public const STATUS_ACTIVE = 'active';

    public const STATUS_SUSPENDED = 'suspended';

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'last_seen_at' => 'datetime',
            'fleet_size' => 'integer',
            'password' => 'hashed',
        ];
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class)->latest('starts_at');
    }

    /** The subscription that currently decides this user's access, if any. */
    public function activeSubscription(): HasOne
    {
        // Constraints go inside ofMany() so an older running subscription is
        // still found when a newer one is cancelled or scheduled.
        return $this->hasOne(Subscription::class)->ofMany(
            ['starts_at' => 'max', 'id' => 'max'],
            fn ($q) => $q->where('status', Subscription::STATUS_ACTIVE)
                ->where('starts_at', '<=', now())
                ->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>', now())),
        );
    }

    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class)->latest('last_seen_at');
    }

    public function screenViews(): HasMany
    {
        return $this->hasMany(ScreenView::class);
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }

    /** Normalises Bangladeshi numbers to 01XXXXXXXXX. */
    public static function normalizePhone(?string $phone): ?string
    {
        if ($phone === null) {
            return null;
        }
        $digits = preg_replace('/\D+/', '', strtr($phone, ['০' => '0', '১' => '1', '২' => '2', '৩' => '3', '৪' => '4', '৫' => '5', '৬' => '6', '৭' => '7', '৮' => '8', '৯' => '9']));
        if (str_starts_with($digits, '880')) {
            $digits = substr($digits, 2);
        }

        return $digits;
    }
}
