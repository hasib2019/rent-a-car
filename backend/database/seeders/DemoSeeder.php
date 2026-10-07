<?php

namespace Database\Seeders;

use App\Models\ScreenView;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

/**
 * Fake owners and ~2 months of screen activity so the dashboard has
 * something to show. Never run this in production.
 */
class DemoSeeder extends Seeder
{
    private const FIRST = ['Rafiq', 'Jamal', 'Sumon', 'Kamal', 'Hasan', 'Rubel', 'Shahin', 'Mizan', 'Nasir', 'Alamgir', 'Sohel', 'Babul', 'Anwar', 'Faruk', 'Jahid', 'Rasel', 'Monir', 'Selim', 'Arif', 'Tanvir', 'Nazmul', 'Shamim', 'Rina', 'Nasrin', 'Sharmin'];

    private const LAST = ['Islam', 'Hossain', 'Uddin', 'Ahmed', 'Mia', 'Rahman', 'Khan', 'Sarkar', 'Chowdhury', 'Talukder', 'Molla', 'Sheikh', 'Bhuiyan', 'Akter'];

    private const SCREENS = [
        'home' => 30, 'daily_collection' => 12, 'fleet' => 10, 'quick_add' => 8, 'ledger' => 8,
        'vehicle_detail' => 8, 'reports' => 6, 'entry_fuel' => 5, 'trips' => 5, 'driver_detail' => 4,
        'trip_form' => 3, 'trip_detail' => 3, 'entry_expense' => 3, 'settings' => 3, 'maintenance' => 3,
        'visit_form' => 2, 'parties' => 2, 'documents' => 2, 'entry_due' => 2, 'party_detail' => 1,
        'part_form' => 1, 'backup' => 1, 'profile' => 1,
    ];

    public function run(): void
    {
        mt_srand(7);
        $platforms = ['android' => 78, 'web' => 14, 'ios' => 8];
        $models = ['android' => ['Samsung Galaxy A15', 'Xiaomi Redmi 13C', 'Realme C55', 'Symphony Z70', 'Walton Primo R10'], 'ios' => ['iPhone 12', 'iPhone 13'], 'web' => ['Chrome', 'Edge']];
        $pool = [];
        foreach (self::SCREENS as $screen => $w) {
            array_push($pool, ...array_fill(0, $w, $screen));
        }

        for ($i = 0; $i < 160; $i++) {
            // More sign-ups in recent weeks.
            $daysAgo = (int) floor(60 * (1 - sqrt(mt_rand() / mt_getrandmax())));
            $joined = Carbon::now()->subDays($daysAgo)->setTime(mt_rand(7, 22), mt_rand(0, 59));
            $platform = $this->weighted($platforms);

            $first = self::FIRST[mt_rand(0, count(self::FIRST) - 1)];
            $last = self::LAST[mt_rand(0, count(self::LAST) - 1)];
            $user = User::factory()->create([
                'name' => "$first $last",
                'username' => strtolower($first).mt_rand(10, 9999),
                'email' => strtolower($first.'.'.$last).mt_rand(1, 999).'@example.com',
                'business_name' => mt_rand(0, 2) ? "$last ".['Transport', 'Rent-a-Car', 'Motors', 'Enterprise', 'CNG Service'][mt_rand(0, 4)] : null,
                'created_at' => $joined,
                'updated_at' => $joined,
                'signup_platform' => $platform,
                'last_platform' => $platform,
                'last_app_version' => '1.0.0',
                'last_login_at' => $joined,
                'status' => $i % 53 === 7 ? User::STATUS_SUSPENDED : User::STATUS_ACTIVE,
            ]);

            UserDevice::create([
                'user_id' => $user->id,
                'device_id' => (string) Str::uuid(),
                'platform' => $platform,
                'model' => $models[$platform][array_rand($models[$platform])],
                'os_version' => $platform === 'android' ? 'Android '.mt_rand(11, 15) : ($platform === 'ios' ? 'iOS 18' : 'Web'),
                'app_version' => '1.0.0',
                'last_seen_at' => $joined,
            ]);

            $engagement = mt_rand(15, 95) / 100; // chance of opening the app on a given day
            $rows = [];
            $lastSeen = $joined;
            for ($d = Carbon::parse($joined)->startOfDay(); $d->lte(now()); $d->addDay()) {
                if (mt_rand() / mt_getrandmax() > $engagement) {
                    continue;
                }
                $session = Str::random(12);
                $at = $d->copy()->setTime(mt_rand(6, 22), mt_rand(0, 59));
                if ($at->isFuture()) {
                    continue;
                }
                $rows[] = $this->row($user->id, 'home', $session, $platform, $at);
                for ($n = mt_rand(1, 9); $n > 0; $n--) {
                    $at = $at->copy()->addSeconds(mt_rand(10, 240));
                    $rows[] = $this->row($user->id, $pool[array_rand($pool)], $session, $platform, $at);
                }
                $lastSeen = $at;
            }
            foreach (array_chunk($rows, 500) as $chunk) {
                ScreenView::insert($chunk);
            }
            $user->forceFill(['last_seen_at' => $lastSeen])->saveQuietly();
        }

        $this->command?->info('Demo users: '.User::count().', screen views: '.ScreenView::count());
    }

    private function row(int $userId, string $screen, string $session, string $platform, Carbon $at): array
    {
        return ['user_id' => $userId, 'screen' => $screen, 'session_id' => $session, 'platform' => $platform, 'app_version' => '1.0.0', 'viewed_at' => $at, 'created_at' => $at];
    }

    private function weighted(array $weights): string
    {
        $r = mt_rand(1, array_sum($weights));
        foreach ($weights as $key => $w) {
            if (($r -= $w) <= 0) {
                return $key;
            }
        }

        return array_key_first($weights);
    }
}
