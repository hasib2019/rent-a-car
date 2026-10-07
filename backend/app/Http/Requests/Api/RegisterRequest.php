<?php

namespace App\Http\Requests\Api;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        $this->merge([
            'username' => strtolower(trim((string) $this->input('username'))),
            'email' => strtolower(trim((string) $this->input('email'))),
            'phone' => User::normalizePhone($this->input('phone')),
        ]);
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'username' => ['required', 'string', 'min:3', 'max:30', 'regex:/^[a-z0-9_.]+$/', 'unique:users,username'],
            'email' => ['required', 'string', 'email', 'max:150', 'unique:users,email'],
            'phone' => ['required', 'regex:/^01[3-9]\d{8}$/', 'unique:users,phone'],
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
            'business_name' => ['nullable', 'string', 'max:120'],
            'district' => ['nullable', 'string', 'max:60'],
            'fleet_size' => ['nullable', 'integer', 'min:0', 'max:5000'],
            'device' => ['nullable', 'array'],
            'device.id' => ['nullable', 'string', 'max:100'],
            'device.platform' => ['nullable', 'string', 'max:20'],
            'device.model' => ['nullable', 'string', 'max:100'],
            'device.os_version' => ['nullable', 'string', 'max:50'],
            'device.app_version' => ['nullable', 'string', 'max:20'],
        ];
    }

    public function attributes(): array
    {
        return __('api.attributes');
    }
}
