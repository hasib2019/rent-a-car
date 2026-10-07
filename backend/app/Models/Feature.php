<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

/**
 * A capability of the app that packages can include. The `key` is what the
 * app checks, so keys must match the constants in the Flutter code.
 */
#[Fillable(['key', 'name', 'name_bn', 'description', 'group', 'sort_order'])]
class Feature extends Model
{
    public function packages(): BelongsToMany
    {
        return $this->belongsToMany(Package::class);
    }
}
