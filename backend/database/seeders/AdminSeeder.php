<?php

namespace Database\Seeders;

use App\Models\Admin;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/** Creates the first admin from ADMIN_EMAIL / ADMIN_PASSWORD (or a random password). */
class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $email = env('ADMIN_EMAIL', 'admin@garikhata.app');
        if (Admin::where('email', $email)->exists()) {
            return;
        }

        $password = env('ADMIN_PASSWORD') ?: Str::password(14, symbols: false);
        Admin::create(['name' => 'Admin', 'email' => $email, 'password' => $password, 'is_active' => true]);

        $this->command?->info("Admin created → email: $email  password: $password");
    }
}
