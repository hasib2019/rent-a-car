<?php

namespace Tests\Feature\Api;

use App\Mail\PasswordResetCode;
use App\Models\AppSetting;
use App\Models\User;
use Database\Seeders\FeatureSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(FeatureSeeder::class);
    }

    private function payload(array $override = []): array
    {
        return array_merge([
            'name' => 'Rafiqul Islam',
            'username' => 'Rafiq_01',
            'email' => 'Rafiq@Example.com',
            'phone' => '+880 1711-234567',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
            'business_name' => 'Rafiq Transport',
            'district' => 'Dhaka',
            'fleet_size' => 3,
            'device' => ['id' => 'dev-1', 'platform' => 'android', 'model' => 'Pixel 8', 'app_version' => '1.0.0'],
        ], $override);
    }

    public function test_register_normalises_input_and_returns_token_with_full_access(): void
    {
        $res = $this->postJson('/api/v1/auth/register', $this->payload())->assertCreated();

        $res->assertJsonPath('user.username', 'rafiq_01')
            ->assertJsonPath('user.email', 'rafiq@example.com')
            ->assertJsonPath('user.phone', '01711234567')
            ->assertJsonPath('access.mode', 'full')
            ->assertJsonPath('access.features.reports', true)
            ->assertJsonPath('access.limits.max_vehicles', null);
        $this->assertNotEmpty($res->json('token'));
        $this->assertDatabaseHas('user_devices', ['device_id' => 'dev-1', 'platform' => 'android']);
        $this->assertSame('android', User::first()->signup_platform);
    }

    public function test_register_requires_email_and_phone_and_rejects_duplicates(): void
    {
        $this->postJson('/api/v1/auth/register', $this->payload(['email' => '', 'phone' => '']))
            ->assertUnprocessable()->assertJsonValidationErrors(['email', 'phone']);

        $this->postJson('/api/v1/auth/register', $this->payload())->assertCreated();
        $this->postJson('/api/v1/auth/register', $this->payload(['username' => 'other']))
            ->assertUnprocessable()->assertJsonValidationErrors(['email', 'phone']);
    }

    public function test_bad_phone_and_weak_password_fail_with_bangla_messages(): void
    {
        $res = $this->withHeader('Accept-Language', 'bn')
            ->postJson('/api/v1/auth/register', $this->payload(['phone' => '0123', 'password' => 'abc', 'password_confirmation' => 'abc']))
            ->assertUnprocessable();

        $this->assertStringContainsString('মোবাইল', $res->json('errors.phone.0'));
        $this->assertStringContainsString('পাসওয়ার্ড', $res->json('errors.password.0'));
    }

    public function test_login_with_email_phone_or_username(): void
    {
        $this->postJson('/api/v1/auth/register', $this->payload())->assertCreated();

        foreach (['rafiq@example.com', '01711234567', '+8801711234567', 'RAFIQ_01'] as $login) {
            $this->postJson('/api/v1/auth/login', ['login' => $login, 'password' => 'secret123'])
                ->assertOk()->assertJsonStructure(['token', 'user', 'access']);
        }

        $this->postJson('/api/v1/auth/login', ['login' => 'rafiq_01', 'password' => 'wrong'])
            ->assertUnprocessable()->assertJsonValidationErrors('login');
    }

    public function test_suspended_users_cannot_log_in_or_use_tokens(): void
    {
        $user = User::factory()->create(['password' => 'secret123']);
        $token = $user->createToken('t')->plainTextToken;
        $user->update(['status' => User::STATUS_SUSPENDED]);

        $this->postJson('/api/v1/auth/login', ['login' => $user->email, 'password' => 'secret123'])
            ->assertForbidden()->assertJsonPath('code', 'account_suspended');
        $this->withToken($token)->getJson('/api/v1/me')->assertForbidden();
    }

    public function test_password_reset_with_emailed_code(): void
    {
        Mail::fake();
        $user = User::factory()->create(['email' => 'owner@example.com']);
        $user->createToken('old');

        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'owner@example.com'])->assertOk();
        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'nobody@example.com'])->assertOk();

        $code = null;
        Mail::assertSent(PasswordResetCode::class, function ($mail) use (&$code) {
            $code = $mail->code;

            return true;
        });
        Mail::assertSentCount(1);

        $this->postJson('/api/v1/auth/reset-password', ['email' => 'owner@example.com', 'code' => '000000', 'password' => 'newpass99', 'password_confirmation' => 'newpass99'])
            ->assertUnprocessable()->assertJsonValidationErrors('code');
        $this->postJson('/api/v1/auth/reset-password', ['email' => 'owner@example.com', 'code' => $code, 'password' => 'newpass99', 'password_confirmation' => 'newpass99'])
            ->assertOk();

        $this->assertTrue(Hash::check('newpass99', $user->fresh()->password));
        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_registration_can_be_closed_and_maintenance_blocks_api(): void
    {
        AppSetting::put(['registration_open' => false]);
        $this->postJson('/api/v1/auth/register', $this->payload())->assertForbidden()->assertJsonPath('code', 'registration_closed');

        AppSetting::put(['maintenance_mode' => true, 'maintenance_message' => 'Back at 5pm']);
        $this->postJson('/api/v1/auth/login', ['login' => 'x', 'password' => 'y'])->assertStatus(503)->assertJsonPath('message', 'Back at 5pm');
        $this->getJson('/api/v1/config')->assertOk()->assertJsonPath('data.maintenance_mode', true);
    }
}
