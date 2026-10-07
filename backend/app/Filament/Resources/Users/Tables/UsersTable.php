<?php

namespace App\Filament\Resources\Users\Tables;

use App\Filament\Support\AssignPackageAction;
use App\Models\Package;
use App\Models\User;
use Filament\Actions\ActionGroup;
use Filament\Actions\BulkAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DatePicker;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

class UsersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with('activeSubscription.package')->withCount('screenViews'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('name')
                    ->description(fn (User $r) => '@'.$r->username)
                    ->searchable(['name', 'username'])
                    ->weight('semibold'),
                TextColumn::make('phone')->searchable()->copyable()->icon(Heroicon::OutlinedPhone),
                TextColumn::make('email')->searchable()->copyable()->toggleable(),
                TextColumn::make('district')->sortable()->toggleable()->placeholder('—'),
                TextColumn::make('access')->label('Access')->badge()
                    ->state(fn (User $r) => $r->activeSubscription?->package?->name ?? 'Full access')
                    ->color(fn (User $r) => $r->activeSubscription ? 'primary' : 'gray'),
                TextColumn::make('status')->badge()
                    ->color(fn (string $state) => $state === User::STATUS_ACTIVE ? 'success' : 'danger'),
                TextColumn::make('screen_views_count')->label('Screen views')->numeric()->sortable()->alignEnd(),
                TextColumn::make('last_platform')->label('Platform')->badge()->color('gray')->placeholder('—')->toggleable(),
                TextColumn::make('last_seen_at')->label('Last seen')->since()->sortable()->placeholder('Never'),
                TextColumn::make('created_at')->label('Joined')->dateTime('j M Y')->sortable(),
            ])
            ->filters([
                SelectFilter::make('status')->options([User::STATUS_ACTIVE => 'Active', User::STATUS_SUSPENDED => 'Suspended']),
                SelectFilter::make('last_platform')->label('Platform')->options(['android' => 'Android', 'ios' => 'iOS', 'web' => 'Web']),
                SelectFilter::make('package')->label('Package')
                    ->options(fn () => Package::orderBy('sort_order')->pluck('name', 'id'))
                    ->query(fn (Builder $query, array $data) => $query->when($data['value'], fn ($q, $id) => $q->whereHas('subscriptions', fn ($s) => $s->current()->where('package_id', $id)))),
                TernaryFilter::make('has_package')->label('Has a package')
                    ->queries(
                        true: fn (Builder $query) => $query->whereHas('subscriptions', fn ($s) => $s->current()),
                        false: fn (Builder $query) => $query->whereDoesntHave('subscriptions', fn ($s) => $s->current()),
                    ),
                Filter::make('joined')->schema([
                    DatePicker::make('from')->label('Joined from'),
                    DatePicker::make('until')->label('Joined until'),
                ])->query(fn (Builder $query, array $data) => $query
                    ->when($data['from'] ?? null, fn ($q, $d) => $q->whereDate('created_at', '>=', $d))
                    ->when($data['until'] ?? null, fn ($q, $d) => $q->whereDate('created_at', '<=', $d))),
                TernaryFilter::make('active_week')->label('Active in last 7 days')
                    ->queries(
                        true: fn (Builder $query) => $query->where('last_seen_at', '>=', now()->subDays(7)),
                        false: fn (Builder $query) => $query->where(fn ($q) => $q->whereNull('last_seen_at')->orWhere('last_seen_at', '<', now()->subDays(7))),
                    ),
            ])
            ->recordActions([
                ActionGroup::make([
                    ViewAction::make(),
                    EditAction::make(),
                    AssignPackageAction::make(),
                ]),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    BulkAction::make('suspend')->icon(Heroicon::OutlinedNoSymbol)->color('danger')->requiresConfirmation()
                        ->action(function (Collection $records) {
                            $records->each(function (User $u) {
                                $u->update(['status' => User::STATUS_SUSPENDED]);
                                $u->tokens()->delete();
                            });
                        }),
                    BulkAction::make('activate')->icon(Heroicon::OutlinedCheckCircle)->color('success')
                        ->action(fn (Collection $records) => $records->each->update(['status' => User::STATUS_ACTIVE])),
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
