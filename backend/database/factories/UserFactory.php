<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected static ?string $password;

    public function definition(): array
    {
        $name = fake()->name();

        return [
            'name' => $name,
            'username' => Str::lower(Str::slug(Str::words($name, 1, ''), '')).fake()->unique()->numberBetween(10, 99999),
            'email' => fake()->unique()->safeEmail(),
            'phone' => '01'.fake()->randomElement(['3', '4', '5', '6', '7', '8', '9']).fake()->unique()->numerify('########'),
            'business_name' => fake()->optional()->company(),
            'district' => fake()->randomElement(['Dhaka', 'Chattogram', 'Gazipur', 'Narayanganj', 'Sylhet', 'Khulna', 'Rajshahi', 'Cumilla', 'Bogura', 'Mymensingh']),
            'fleet_size' => fake()->numberBetween(1, 8),
            'status' => User::STATUS_ACTIVE,
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password1'),
            'remember_token' => Str::random(10),
        ];
    }

    public function suspended(): static
    {
        return $this->state(fn () => ['status' => User::STATUS_SUSPENDED]);
    }
}
