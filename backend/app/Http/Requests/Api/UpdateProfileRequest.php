<?php

namespace App\Http\Requests\Api;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        $data = [];
        if ($this->has('username')) {
            $data['username'] = strtolower(trim((string) $this->input('username')));
        }
        if ($this->has('email')) {
            $data['email'] = strtolower(trim((string) $this->input('email')));
        }
        if ($this->has('phone')) {
            $data['phone'] = User::normalizePhone($this->input('phone'));
        }
        $this->merge($data);
    }

    public function rules(): array
    {
        $id = $this->user()->id;

        return [
            'name' => ['sometimes', 'required', 'string', 'min:2', 'max:100'],
            'username' => ['sometimes', 'required', 'string', 'min:3', 'max:30', 'regex:/^[a-z0-9_.]+$/', Rule::unique('users')->ignore($id)],
            'email' => ['sometimes', 'required', 'email', 'max:150', Rule::unique('users')->ignore($id)],
            'phone' => ['sometimes', 'required', 'regex:/^01[3-9]\d{8}$/', Rule::unique('users')->ignore($id)],
            'business_name' => ['sometimes', 'nullable', 'string', 'max:120'],
            'district' => ['sometimes', 'nullable', 'string', 'max:60'],
            'fleet_size' => ['sometimes', 'nullable', 'integer', 'min:0', 'max:5000'],
        ];
    }

    public function attributes(): array
    {
        return __('api.attributes');
    }
}
