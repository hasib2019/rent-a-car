<?php

namespace App\Services;

use App\Models\Package;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/** Assigning a package ends whatever package the user was on. */
class SubscriptionManager
{
    public function assign(User $user, Package $package, array $data = [], ?int $adminId = null): Subscription
    {
        $starts = isset($data['starts_at']) ? Carbon::parse($data['starts_at']) : now();
        $ends = array_key_exists('ends_at', $data)
            ? ($data['ends_at'] ? Carbon::parse($data['ends_at']) : null)
            : ($package->duration_days ? $starts->copy()->addDays($package->duration_days) : null);

        return DB::transaction(function () use ($user, $package, $data, $adminId, $starts, $ends) {
            if ($starts->lte(now())) {
                Subscription::query()->current()->where('user_id', $user->id)->update(['ends_at' => $starts]);
            }

            return Subscription::create([
                'user_id' => $user->id,
                'package_id' => $package->id,
                'starts_at' => $starts,
                'ends_at' => $ends,
                'status' => Subscription::STATUS_ACTIVE,
                'amount' => $data['amount'] ?? $package->price,
                'payment_method' => $data['payment_method'] ?? null,
                'payment_ref' => $data['payment_ref'] ?? null,
                'note' => $data['note'] ?? null,
                'created_by' => $adminId,
            ]);
        });
    }

    public function cancel(Subscription $subscription): void
    {
        $subscription->update(['status' => Subscription::STATUS_CANCELLED]);
    }
}
