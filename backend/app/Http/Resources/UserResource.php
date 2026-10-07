<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\User */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'username' => $this->username,
            'email' => $this->email,
            'phone' => $this->phone,
            'business_name' => $this->business_name,
            'district' => $this->district,
            'fleet_size' => $this->fleet_size,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
