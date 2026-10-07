<?php

namespace Database\Seeders;

use App\Models\Feature;
use Illuminate\Database\Seeder;

/** Syncs config/features.php into the features table (safe to re-run). */
class FeatureSeeder extends Seeder
{
    public function run(): void
    {
        foreach (config('features') as $i => $feature) {
            Feature::query()->updateOrCreate(['key' => $feature['key']], [...$feature, 'sort_order' => $i]);
        }
    }
}
