<?php

namespace App\Services;

use App\Models\ScreenView;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * Read-only queries behind the admin dashboard and analytics pages.
 */
class Analytics
{
    /** @return array<string,int> Y-m-d => count, oldest first, zero-filled */
    public static function signupsPerDay(int $days): array
    {
        $from = now()->subDays($days - 1)->startOfDay();
        $rows = User::query()
            ->where('created_at', '>=', $from)
            ->selectRaw('DATE(created_at) as d, COUNT(*) as c')
            ->groupBy('d')
            ->pluck('c', 'd');

        return self::fill($from, $days, $rows);
    }

    /** Distinct users who opened any screen, per day. */
    public static function activeUsersPerDay(int $days): array
    {
        $from = now()->subDays($days - 1)->startOfDay();
        $rows = ScreenView::query()
            ->where('viewed_at', '>=', $from)
            ->selectRaw('DATE(viewed_at) as d, COUNT(DISTINCT user_id) as c')
            ->groupBy('d')
            ->pluck('c', 'd');

        return self::fill($from, $days, $rows);
    }

    public static function viewsPerDay(int $days): array
    {
        $from = now()->subDays($days - 1)->startOfDay();
        $rows = ScreenView::query()
            ->where('viewed_at', '>=', $from)
            ->selectRaw('DATE(viewed_at) as d, COUNT(*) as c')
            ->groupBy('d')
            ->pluck('c', 'd');

        return self::fill($from, $days, $rows);
    }

    public static function activeUsersSince(Carbon $from): int
    {
        return ScreenView::query()->where('viewed_at', '>=', $from)->distinct()->count('user_id');
    }

    /**
     * Per-screen totals.
     *
     * @return Collection<int, array{screen:string, label:string, views:int, users:int, last:?string}>
     */
    public static function screens(?Carbon $from = null, ?Carbon $to = null, ?string $platform = null): Collection
    {
        return ScreenView::query()
            ->when($from, fn ($q) => $q->where('viewed_at', '>=', $from))
            ->when($to, fn ($q) => $q->where('viewed_at', '<=', $to))
            ->when($platform, fn ($q) => $q->where('platform', $platform))
            ->selectRaw('screen, COUNT(*) as views, COUNT(DISTINCT user_id) as users, MAX(viewed_at) as last')
            ->groupBy('screen')
            ->orderByDesc('views')
            ->get()
            ->map(fn ($r) => [
                'screen' => $r->screen,
                'label' => ScreenView::label($r->screen),
                'views' => (int) $r->views,
                'users' => (int) $r->users,
                'last' => $r->last,
            ]);
    }

    /** @return array<string,int> package name => users currently on it, plus users on full access */
    public static function packageDistribution(): array
    {
        $running = Subscription::query()->current()
            ->join('packages', 'packages.id', '=', 'subscriptions.package_id')
            ->selectRaw('packages.name as name, COUNT(DISTINCT subscriptions.user_id) as c')
            ->groupBy('packages.name')
            ->pluck('c', 'name')
            ->all();

        $withPackage = Subscription::query()->current()->distinct()->count('user_id');

        return ['No package (full access)' => max(0, User::count() - $withPackage)] + $running;
    }

    /** @return array<string,int> */
    public static function platforms(): array
    {
        return User::query()
            ->selectRaw("COALESCE(last_platform, 'unknown') as p, COUNT(*) as c")
            ->groupBy('p')
            ->orderByDesc('c')
            ->pluck('c', 'p')
            ->all();
    }

    private static function fill(Carbon $from, int $days, $rows): array
    {
        $out = [];
        for ($i = 0; $i < $days; $i++) {
            $d = $from->copy()->addDays($i)->toDateString();
            $out[$d] = (int) ($rows[$d] ?? 0);
        }

        return $out;
    }

    /** Short x-axis labels: "7 Oct". */
    public static function labels(array $series): array
    {
        return array_map(fn ($d) => Carbon::parse($d)->format('j M'), array_keys($series));
    }

}
