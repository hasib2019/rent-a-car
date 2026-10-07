<?php

namespace Tests\Feature\Api;

use App\Models\AppSetting;
use App\Models\Feature;
use App\Models\Package;
use App\Models\Subscription;
use App\Models\User;
use Database\Seeders\FeatureSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfileAndAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(FeatureSeeder::class);
    }

    private function basicPackage(): Package
    {
        $package = Package::create(['name' => 'Basic', 'price' => 199, 'duration_days' => 30, 'max_vehicles' => 2, 'max_drivers' => 2]);
        $package->features()->sync(Feature::whereIn('key', ['daily_collection', 'fuel_expense'])->pluck('id'));

        return $package;
    }

    public function test_users_without_a_package_get_everything(): void
    {
        $user = User::factory()->create();
        $access = $this->actingAs($user)->getJson('/api/v1/me')->assertOk()->json('access');

        $this->assertSame('full', $access['mode']);
        $this->assertCount(Feature::count(), array_filter($access['features']));
    }

    public function test_a_running_package_decides_features_and_limits(): void
    {
        $user = User::factory()->create();
        Subscription::create(['user_id' => $user->id, 'package_id' => $this->basicPackage()->id, 'starts_at' => now()->subDay(), 'ends_at' => now()->addDays(29)]);

        $access = $this->actingAs($user)->getJson('/api/v1/me')->json('access');

        $this->assertSame('package', $access['mode']);
        $this->assertTrue($access['features']['daily_collection']);
        $this->assertFalse($access['features']['reports']);
        $this->assertSame(2, $access['limits']['max_vehicles']);
        $this->assertNotNull($access['expires_at']);
    }

    public function test_expired_or_cancelled_packages_fall_back_to_full_access(): void
    {
        $user = User::factory()->create();
        $package = $this->basicPackage();
        Subscription::create(['user_id' => $user->id, 'package_id' => $package->id, 'starts_at' => now()->subDays(40), 'ends_at' => now()->subDays(10)]);
        Subscription::create(['user_id' => $user->id, 'package_id' => $package->id, 'starts_at' => now()->subDay(), 'status' => Subscription::STATUS_CANCELLED]);

        $this->actingAs($user)->getJson('/api/v1/me')->assertJsonPath('access.mode', 'full');
    }

    public function test_a_newer_cancelled_or_scheduled_subscription_does_not_hide_the_running_one(): void
    {
        $user = User::factory()->create();
        $package = $this->basicPackage();
        Subscription::create(['user_id' => $user->id, 'package_id' => $package->id, 'starts_at' => now()->subDays(5), 'ends_at' => now()->addDays(25)]);
        Subscription::create(['user_id' => $user->id, 'package_id' => $package->id, 'starts_at' => now()->subDay(), 'status' => Subscription::STATUS_CANCELLED]);
        Subscription::create(['user_id' => $user->id, 'package_id' => $package->id, 'starts_at' => now()->addDays(25)]);

        $this->actingAs($user)->getJson('/api/v1/me')->assertJsonPath('access.mode', 'package');
        $this->assertSame(2, User::with('activeSubscription.package')->find($user->id)->activeSubscription->package->max_vehicles);
    }

    public function test_admin_can_set_a_fallback_package_for_users_without_one(): void
    {
        AppSetting::put(['no_package_access' => (string) $this->basicPackage()->id]);
        $user = User::factory()->create();

        $this->actingAs($user)->getJson('/api/v1/me')
            ->assertJsonPath('access.mode', 'fallback')
            ->assertJsonPath('access.features.trips', false);
    }

    public function test_profile_update_change_password_and_delete_account(): void
    {
        $user = User::factory()->create(['password' => 'secret123']);
        $token = $user->createToken('a')->plainTextToken;
        $other = $user->createToken('b');

        $this->withToken($token)->putJson('/api/v1/me', ['name' => 'New Name', 'phone' => '01812345678'])
            ->assertOk()->assertJsonPath('user.name', 'New Name')->assertJsonPath('user.phone', '01812345678');

        $this->withToken($token)->putJson('/api/v1/me/password', ['current_password' => 'nope', 'password' => 'newpass99', 'password_confirmation' => 'newpass99'])
            ->assertUnprocessable();
        $this->withToken($token)->putJson('/api/v1/me/password', ['current_password' => 'secret123', 'password' => 'newpass99', 'password_confirmation' => 'newpass99'])
            ->assertOk();
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $other->accessToken->id]);

        $this->withToken($token)->deleteJson('/api/v1/me', ['password' => 'newpass99'])->assertNoContent();
        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }

    public function test_screen_events_are_stored_and_validated(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->withHeaders(['X-Platform' => 'android', 'X-App-Version' => '1.0.0'])
            ->postJson('/api/v1/events', ['events' => [
                ['screen' => 'home', 'viewed_at' => now()->subMinute()->toIso8601String(), 'session_id' => 's1'],
                ['screen' => 'reports', 'viewed_at' => now()->addYear()->toIso8601String()],
            ]])->assertStatus(202)->assertJsonPath('accepted', 2);

        $this->assertDatabaseHas('screen_views', ['user_id' => $user->id, 'screen' => 'home', 'platform' => 'android']);
        $this->assertTrue($user->screenViews()->where('screen', 'reports')->first()->viewed_at->lte(now()->addMinute()));

        $this->actingAs($user)->postJson('/api/v1/events', ['events' => [['screen' => 'Bad Screen!']]])->assertUnprocessable();
    }

    public function test_events_and_profile_require_a_token(): void
    {
        $this->postJson('/api/v1/events', ['events' => [['screen' => 'home']]])->assertUnauthorized();
        $this->getJson('/api/v1/me')->assertUnauthorized();
    }
}
