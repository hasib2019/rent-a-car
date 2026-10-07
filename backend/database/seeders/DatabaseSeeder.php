<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Production-safe seed: app features + the first admin.
     * Demo users / analytics: php artisan db:seed --class=DemoSeeder
     */
    public function run(): void
    {
        $this->call([FeatureSeeder::class, AdminSeeder::class]);
    }
}
