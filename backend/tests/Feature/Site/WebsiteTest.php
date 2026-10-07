<?php

namespace Tests\Feature\Site;

use App\Models\Admin;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WebsiteTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_pages_render_in_bangla_and_english(): void
    {
        $this->get('/')->assertOk()->assertSee('গাড়ির খাতা')->assertSee(route('login'));
        $this->get('/privacy')->assertOk();
        $this->get('/account-deletion')->assertOk();

        $this->get('/lang/en')->assertRedirect();
        $this->get('/')->assertOk()->assertSee('GariKhata')->assertSee('Which vehicle earned what');
    }

    public function test_admin_panel_sends_guests_to_the_website_login(): void
    {
        $this->get('/admin/login')->assertRedirect(route('login'));
        $this->get('/l')->assertRedirect('/login');
        $this->get('/login')->assertOk()->assertSee('name="email"', false);
    }

    public function test_admin_logs_in_from_the_website_and_lands_on_the_panel(): void
    {
        Admin::create(['name' => 'Boss', 'email' => 'boss@example.com', 'password' => 'secret123', 'is_active' => true]);

        $this->post('/login', ['email' => 'boss@example.com', 'password' => 'nope'])->assertSessionHasErrors('email');
        $this->assertGuest('admin');

        $this->post('/login', ['email' => 'BOSS@example.com', 'password' => 'secret123'])->assertRedirect('/admin');
        $this->assertAuthenticated('admin');
        $this->get('/admin')->assertOk();
        $this->get('/login')->assertRedirect('/admin');

        $this->post('/logout')->assertRedirect(route('login'));
        $this->assertGuest('admin');
    }

    public function test_disabled_admins_and_brute_force_are_blocked(): void
    {
        Admin::create(['name' => 'Old', 'email' => 'old@example.com', 'password' => 'secret123', 'is_active' => false]);
        $this->post('/login', ['email' => 'old@example.com', 'password' => 'secret123'])->assertSessionHasErrors('email');
        $this->assertGuest('admin');

        foreach (range(1, 5) as $_) {
            $this->post('/login', ['email' => 'x@example.com', 'password' => 'bad']);
        }
        $this->post('/login', ['email' => 'x@example.com', 'password' => 'bad'])
            ->assertSessionHasErrors(['email' => __('site.login.throttle', ['seconds' => 60])]);
    }

    public function test_android_download_falls_back_when_the_apk_is_missing(): void
    {
        $apk = public_path('downloads/garikhata.apk');
        if (is_file($apk)) {
            $this->get('/download/android')->assertOk()->assertHeader('content-type', 'application/vnd.android.package-archive');
        } else {
            $this->get('/download/android')->assertRedirect(route('home'));
        }
    }
}
