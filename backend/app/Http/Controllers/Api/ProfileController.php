<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Services\AccessResolver;
use App\Services\DeviceTracker;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class ProfileController extends Controller
{
    public function __construct(private AccessResolver $access) {}

    /** Profile + current access. The app calls this on every start. */
    public function show(Request $request, DeviceTracker $devices): JsonResponse
    {
        $user = $request->user();
        $devices->record($user, $request);

        return response()->json([
            'user' => new UserResource($user),
            'access' => $this->access->for($user),
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->fill($request->validated())->save();

        return response()->json(['user' => new UserResource($user)]);
    }

    public function password(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
        ], [], __('api.attributes'));

        $user = $request->user();
        if (! Hash::check($data['current_password'], $user->password)) {
            throw ValidationException::withMessages(['current_password' => __('api.wrong_password')]);
        }

        $user->forceFill(['password' => $data['password']])->save();
        // Sign out every other device.
        $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();

        return response()->json(['message' => __('api.password_changed')]);
    }

    /** Permanent account deletion (required by Google Play / App Store). */
    public function destroy(Request $request): JsonResponse
    {
        $data = $request->validate(['password' => ['required', 'string']], [], __('api.attributes'));
        $user = $request->user();

        if (! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['password' => __('api.wrong_password')]);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json(null, 204);
    }
}
