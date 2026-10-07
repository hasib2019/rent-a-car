<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Mail\PasswordResetCode;
use App\Models\AppSetting;
use App\Models\User;
use App\Services\AccessResolver;
use App\Services\DeviceTracker;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(private AccessResolver $access, private DeviceTracker $devices) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        if (! AppSetting::get('registration_open', true)) {
            return response()->json(['code' => 'registration_closed', 'message' => __('api.registration_closed')], 403);
        }

        $user = User::create([
            ...$request->safe()->except(['device', 'password_confirmation']),
            'status' => User::STATUS_ACTIVE,
            'signup_platform' => $request->input('device.platform') ?? $request->header('X-Platform'),
            'last_login_at' => now(),
        ]);

        return $this->issue($user, $request, 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'login' => ['required', 'string', 'max:150'],
            'password' => ['required', 'string'],
            'device' => ['nullable', 'array'],
        ], [], __('api.attributes'));

        $login = strtolower(trim($data['login']));
        $user = User::query()
            ->where('email', $login)
            ->orWhere('username', $login)
            ->orWhere('phone', User::normalizePhone($login) ?: '-')
            ->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['login' => __('api.invalid_credentials')]);
        }

        if (! $user->isActive()) {
            return response()->json(['code' => 'account_suspended', 'message' => __('api.suspended')], 403);
        }

        $user->forceFill(['last_login_at' => now()])->saveQuietly();

        return $this->issue($user, $request);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(null, 204);
    }

    /** Emails a 6-digit code. Always answers the same to avoid account probing. */
    public function forgotPassword(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']], [], __('api.attributes'));
        $email = strtolower(trim($data['email']));
        $user = User::where('email', $email)->first();

        if ($user && $user->isActive()) {
            $code = (string) random_int(100000, 999999);
            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $email],
                ['token' => Hash::make($code), 'created_at' => now()],
            );
            Mail::to($email)->send(new PasswordResetCode($user->name, $code));
        }

        return response()->json(['message' => __('api.reset_code_sent')]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'digits:6'],
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
        ], [], __('api.attributes'));

        $email = strtolower(trim($data['email']));
        $row = DB::table('password_reset_tokens')->where('email', $email)->first();
        $valid = $row
            && now()->diffInMinutes($row->created_at, true) <= 15
            && Hash::check($data['code'], $row->token);

        if (! $valid) {
            throw ValidationException::withMessages(['code' => __('api.invalid_code')]);
        }

        $user = User::where('email', $email)->firstOrFail();
        $user->forceFill(['password' => $data['password'], 'remember_token' => Str::random(60)])->save();
        $user->tokens()->delete();
        DB::table('password_reset_tokens')->where('email', $email)->delete();

        return response()->json(['message' => __('api.password_reset')]);
    }

    private function issue(User $user, Request $request, int $status = 200): JsonResponse
    {
        $this->devices->record($user, $request);
        $name = $request->input('device.model') ?: ($request->input('device.platform') ?: 'app');
        $token = $user->createToken(substr($name, 0, 60))->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => new UserResource($user),
            'access' => $this->access->for($user),
        ], $status);
    }
}
