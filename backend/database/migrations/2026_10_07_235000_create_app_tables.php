<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Panel administrators are kept apart from app users.
        Schema::create('admins', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->rememberToken();
            $table->timestamps();
        });

        // App capabilities a package can switch on. Keys are referenced by the app.
        Schema::create('features', function (Blueprint $table) {
            $table->id();
            $table->string('key', 50)->unique();
            $table->string('name');
            $table->string('name_bn')->nullable();
            $table->string('description')->nullable();
            $table->string('group', 40)->default('general');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('packages', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2)->default(0);
            $table->unsignedInteger('duration_days')->nullable()->comment('null = never expires');
            $table->unsignedInteger('max_vehicles')->nullable()->comment('null = unlimited');
            $table->unsignedInteger('max_drivers')->nullable()->comment('null = unlimited');
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('feature_package', function (Blueprint $table) {
            $table->foreignId('package_id')->constrained()->cascadeOnDelete();
            $table->foreignId('feature_id')->constrained()->cascadeOnDelete();
            $table->primary(['package_id', 'feature_id']);
        });

        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('package_id')->constrained()->restrictOnDelete();
            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->nullable();
            $table->string('status', 20)->default('active');
            $table->decimal('amount', 10, 2)->default(0);
            $table->string('payment_method', 40)->nullable();
            $table->string('payment_ref', 100)->nullable();
            $table->text('note')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('admins')->nullOnDelete();
            $table->timestamps();
            $table->index(['user_id', 'status']);
        });

        // One row per screen opened in the app.
        Schema::create('screen_views', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('screen', 80);
            $table->string('session_id', 64)->nullable();
            $table->string('platform', 20)->nullable();
            $table->string('app_version', 20)->nullable();
            $table->timestamp('viewed_at');
            $table->timestamp('created_at')->nullable();
            $table->index(['screen', 'viewed_at']);
            $table->index(['user_id', 'viewed_at']);
            $table->index('viewed_at');
        });

        Schema::create('user_devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('device_id', 100);
            $table->string('platform', 20)->nullable();
            $table->string('model', 100)->nullable();
            $table->string('os_version', 50)->nullable();
            $table->string('app_version', 20)->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'device_id']);
        });

        Schema::create('app_settings', function (Blueprint $table) {
            $table->string('key', 80)->primary();
            $table->text('value')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_settings');
        Schema::dropIfExists('user_devices');
        Schema::dropIfExists('screen_views');
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('feature_package');
        Schema::dropIfExists('packages');
        Schema::dropIfExists('features');
        Schema::dropIfExists('admins');
    }
};
