<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A package assigned to a user for a period.
 */
#[Fillable(['user_id', 'package_id', 'starts_at', 'ends_at', 'status', 'amount', 'payment_method', 'payment_ref', 'note', 'created_by'])]
class Subscription extends Model
{
    public const STATUS_ACTIVE = 'active';

    public const STATUS_CANCELLED = 'cancelled';

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'amount' => 'decimal:2',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function package(): BelongsTo
    {
        return $this->belongsTo(Package::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'created_by');
    }

    public function scopeCurrent(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_ACTIVE)
            ->where('starts_at', '<=', now())
            ->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>', now()));
    }

    /** Human state: running, scheduled, expired or cancelled. */
    public function state(): string
    {
        if ($this->status === self::STATUS_CANCELLED) {
            return 'cancelled';
        }
        if ($this->starts_at?->isFuture()) {
            return 'scheduled';
        }
        if ($this->ends_at !== null && $this->ends_at->isPast()) {
            return 'expired';
        }

        return 'running';
    }
}
