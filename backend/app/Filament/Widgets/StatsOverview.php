<?php

namespace App\Filament\Widgets;

use App\Models\ScreenView;
use App\Models\User;
use App\Services\Analytics;
use Filament\Support\Icons\Heroicon;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends StatsOverviewWidget
{
    protected static ?int $sort = 1;

    protected int|string|array $columnSpan = 'full';

    protected ?string $pollingInterval = '60s';

    protected function getColumns(): int
    {
        return 3;
    }

    protected function getStats(): array
    {
        $total = User::count();
        $signups = Analytics::signupsPerDay(14);
        $today = now()->startOfDay();
        $newToday = User::where('created_at', '>=', $today)->count();
        $newYesterday = User::whereBetween('created_at', [$today->copy()->subDay(), $today])->count();
        $last7 = array_sum(array_slice($signups, -7));
        $dau = Analytics::activeUsersSince($today);
        $wau = Analytics::activeUsersSince(now()->subDays(6)->startOfDay());
        $online = User::where('last_seen_at', '>=', now()->subMinutes(15))->count();
        $viewsToday = ScreenView::where('viewed_at', '>=', $today)->count();
        $activeSeries = array_values(Analytics::activeUsersPerDay(14));

        return [
            Stat::make('Total users', number_format($total))
                ->description("+$last7 in the last 7 days")
                ->descriptionIcon(Heroicon::ArrowTrendingUp)
                ->chart(array_values($signups))
                ->color('primary'),
            Stat::make('New today', number_format($newToday))
                ->description("Yesterday: $newYesterday")
                ->descriptionIcon($newToday >= $newYesterday ? Heroicon::ArrowTrendingUp : Heroicon::ArrowTrendingDown)
                ->color($newToday >= $newYesterday ? 'success' : 'warning'),
            Stat::make('Online now', number_format($online))
                ->description('Active in the last 15 minutes')
                ->descriptionIcon(Heroicon::Signal)
                ->color('info'),
            Stat::make('Active today', number_format($dau))
                ->description($total ? round($dau / $total * 100).'% of all users' : '—')
                ->chart($activeSeries)
                ->color('success'),
            Stat::make('Active this week', number_format($wau))
                ->description($total ? round($wau / $total * 100).'% of all users' : '—')
                ->descriptionIcon(Heroicon::UserGroup),
            Stat::make('Screen views today', number_format($viewsToday))
                ->description($dau ? round($viewsToday / $dau, 1).' per active user' : 'No activity yet')
                ->descriptionIcon(Heroicon::CursorArrowRays),
        ];
    }
}
