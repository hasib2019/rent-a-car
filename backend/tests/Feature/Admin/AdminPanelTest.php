<?php

namespace Tests\Feature\Admin;

use App\Filament\Pages\AppSettings;
use App\Filament\Resources\Packages\Pages\CreatePackage;
use App\Filament\Resources\Users\Pages\ViewUser;
use App\Models\Admin;
use App\Models\AppSetting;
use App\Models\Feature;
use App\Models\Package;
use App\Models\ScreenView;
use App\Models\Subscription;
use App\Models\User;
use Database\Seeders\FeatureSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Livewire\Livewire;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    private Admin $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(FeatureSeeder::class);
        $this->admin = Admin::create(['name' => 'Boss', 'email' => 'boss@example.com', 'password' => 'secret123', 'is_active' => true]);
    }

    private function data(): User
    {
        $users = User::factory()->count(3)->create();
        $package = Package::create(['name' => 'Pro', 'price' => 499, 'duration_days' => 30]);
        $package->features()->sync(Feature::pluck('id'));
        Subscription::create(['user_id' => $users[0]->id, 'package_id' => $package->id, 'starts_at' => now()->subDay(), 'ends_at' => now()->addDays(29)]);
        foreach ($users as $u) {
            ScreenView::create(['user_id' => $u->id, 'screen' => 'home', 'platform' => 'android', 'viewed_at' => now()]);
            ScreenView::create(['user_id' => $u->id, 'screen' => 'reports', 'platform' => 'android', 'viewed_at' => now()->subDays(2)]);
        }

        return $users[0];
    }

    public function test_guests_are_sent_to_login_and_app_users_cannot_enter(): void
    {
        $this->get('/admin')->assertRedirect('/admin/login');
        $this->actingAs(User::factory()->create())->get('/admin')->assertRedirect('/admin/login');
    }

    public function test_every_admin_page_renders(): void
    {
        $user = $this->data();
        $this->actingAs($this->admin, 'admin');

        foreach ([
            '/admin', '/admin/users', '/admin/users/create', "/admin/users/{$user->id}", "/admin/users/{$user->id}/edit",
            '/admin/packages', '/admin/packages/create', '/admin/packages/'.Package::first()->id.'/edit',
            '/admin/features', '/admin/subscriptions', '/admin/screen-analytics', '/admin/screen-views',
            '/admin/app-settings', '/admin/admins',
        ] as $url) {
            $this->get($url)->assertOk();
        }
    }

    public function test_create_package_with_features(): void
    {
        $this->actingAs($this->admin, 'admin');
        $features = Feature::whereIn('key', ['daily_collection', 'reports'])->pluck('id')->all();

        Livewire::test(CreatePackage::class)
            ->fillForm(['name' => 'Basic', 'price' => 199, 'duration_days' => 30, 'max_vehicles' => 2, 'features' => $features])
            ->call('create')
            ->assertHasNoFormErrors();

        $package = Package::where('name', 'Basic')->first();
        $this->assertNotNull($package?->slug);
        $this->assertEqualsCanonicalizing($features, $package->features->pluck('id')->all());
    }

    public function test_assign_package_from_user_page_changes_api_access(): void
    {
        $this->actingAs($this->admin, 'admin');
        $user = User::factory()->create();
        $package = Package::create(['name' => 'Lite', 'price' => 99, 'duration_days' => 30, 'max_vehicles' => 1]);
        $package->features()->sync(Feature::where('key', 'daily_collection')->pluck('id'));

        Livewire::test(ViewUser::class, ['record' => $user->getRouteKey()])
            ->callAction('assignPackage', ['package_id' => $package->id, 'starts_at' => now()->subMinute()->toDateTimeString(), 'ends_at' => now()->addDays(30)->toDateTimeString(), 'amount' => 99, 'payment_method' => 'bkash'])
            ->assertHasNoActionErrors();

        $sub = $user->subscriptions()->first();
        $this->assertSame($this->admin->id, $sub->created_by);

        Sanctum::actingAs($user);
        $this->getJson('/api/v1/me')
            ->assertJsonPath('access.mode', 'package')
            ->assertJsonPath('access.features.reports', false)
            ->assertJsonPath('access.limits.max_vehicles', 1);
    }

    public function test_settings_page_saves(): void
    {
        $this->actingAs($this->admin, 'admin');

        Livewire::test(AppSettings::class)
            ->fillForm(['support_phone' => '01700000000', 'registration_open' => false, 'no_package_access' => 'full', 'min_app_version' => '1.0.0', 'latest_app_version' => '1.1.0'])
            ->call('save')
            ->assertHasNoFormErrors();

        $this->assertSame('01700000000', AppSetting::get('support_phone'));
        $this->assertFalse(AppSetting::get('registration_open'));
        $this->getJson('/api/v1/config')->assertJsonPath('data.latest_app_version', '1.1.0');
    }
}
