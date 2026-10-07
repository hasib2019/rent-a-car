<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'screen', 'session_id', 'platform', 'app_version', 'viewed_at'])]
class ScreenView extends Model
{
    public const UPDATED_AT = null;

    protected function casts(): array
    {
        return ['viewed_at' => 'datetime'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** Readable name for a screen key, from config/screens.php. */
    public static function label(?string $screen): string
    {
        if ($screen === null) {
            return '—';
        }

        return config("screens.$screen") ?? str($screen)->replace('_', ' ')->title()->toString();
    }
}
