<?php

namespace App\Filament\Resources\Users\Schemas;

use App\Models\Feature;
use App\Models\ScreenView;
use App\Models\User;
use App\Services\AccessResolver;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;

class UserInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->columns(3)->components([
            Section::make('Profile')->icon(Heroicon::OutlinedUser)->columns(2)->columnSpan(2)->schema([
                TextEntry::make('name')->weight('bold')->size('lg'),
                TextEntry::make('username')->prefix('@'),
                TextEntry::make('email')->copyable()->icon(Heroicon::OutlinedEnvelope),
                TextEntry::make('phone')->copyable()->icon(Heroicon::OutlinedPhone)
                    ->url(fn (User $record) => 'tel:'.$record->phone),
                TextEntry::make('business_name')->placeholder('—'),
                TextEntry::make('district')->placeholder('—'),
                TextEntry::make('fleet_size')->label('Vehicles (said at sign-up)')->placeholder('—'),
                TextEntry::make('status')->badge()
                    ->color(fn (string $state) => $state === User::STATUS_ACTIVE ? 'success' : 'danger'),
                TextEntry::make('admin_note')->label('Internal note')->placeholder('—')->columnSpanFull(),
            ]),
            Grid::make(1)->columnSpan(1)->schema([
                Section::make('Access')->icon(Heroicon::OutlinedKey)->schema([
                    TextEntry::make('access_mode')->label('Current access')->badge()
                        ->state(function (User $record) {
                            $sub = $record->activeSubscription;

                            return $sub ? $sub->package->name : 'Full access (no package)';
                        })
                        ->color(fn (User $record) => $record->activeSubscription ? 'primary' : 'gray'),
                    TextEntry::make('access_expires')->label('Package ends')
                        ->state(fn (User $record) => $record->activeSubscription?->ends_at?->format('j M Y, g:i a') ?? ($record->activeSubscription ? 'Never' : '—')),
                    TextEntry::make('access_features')->label('Features in the app')->badge()
                        ->state(function (User $record) {
                            $access = app(AccessResolver::class)->for($record);
                            $names = Feature::pluck('name', 'key');

                            return collect($access['features'])->filter()->keys()->map(fn ($k) => $names[$k] ?? $k)->values()->all();
                        }),
                    TextEntry::make('access_limits')->label('Limits')
                        ->state(function (User $record) {
                            $l = app(AccessResolver::class)->for($record)['limits'];

                            return 'Vehicles: '.($l['max_vehicles'] ?? '∞').' · Drivers: '.($l['max_drivers'] ?? '∞');
                        }),
                ]),
                Section::make('Activity')->icon(Heroicon::OutlinedSignal)->schema([
                    TextEntry::make('created_at')->label('Joined')->dateTime('j M Y, g:i a'),
                    TextEntry::make('last_seen_at')->label('Last seen')->since()->placeholder('Never'),
                    TextEntry::make('last_platform')->label('Platform / version')
                        ->state(fn (User $record) => trim(ucfirst((string) $record->last_platform).' '.($record->last_app_version ? 'v'.$record->last_app_version : '')) ?: '—'),
                    TextEntry::make('top_screens')->label('Most used screens')->badge()->color('gray')
                        ->state(fn (User $record) => $record->screenViews()
                            ->selectRaw('screen, COUNT(*) as c')->groupBy('screen')->orderByDesc('c')->limit(6)->get()
                            ->map(fn ($r) => ScreenView::label($r->screen).' · '.$r->c)->all() ?: ['No activity yet']),
                ]),
            ]),
        ]);
    }
}
