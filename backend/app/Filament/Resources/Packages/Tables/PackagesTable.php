<?php

namespace App\Filament\Resources\Packages\Tables;

use App\Models\Package;
use Filament\Actions\EditAction;
use Filament\Actions\ReplicateAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ToggleColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class PackagesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query
                ->withCount('features')
                ->withCount(['subscriptions as users_count' => fn ($s) => $s->current()]))
            ->defaultSort('sort_order')
            ->reorderable('sort_order')
            ->columns([
                TextColumn::make('name')->weight('bold')->searchable()
                    ->description(fn (Package $r) => str($r->description)->limit(60)->toString() ?: null),
                TextColumn::make('price')->money('BDT')->sortable(),
                TextColumn::make('duration_days')->label('Duration')
                    ->formatStateUsing(fn ($state) => $state ? "$state days" : 'Never expires')
                    ->placeholder('Never expires'),
                TextColumn::make('limits')->label('Limits')
                    ->state(fn (Package $r) => 'Vehicles '.($r->max_vehicles ?? '∞').' · Drivers '.($r->max_drivers ?? '∞')),
                TextColumn::make('features_count')->label('Features')->badge()->color('gray'),
                TextColumn::make('users_count')->label('Users now')->badge()->color('primary'),
                ToggleColumn::make('is_active')->label('Active'),
            ])
            ->recordActions([
                EditAction::make(),
                ReplicateAction::make()->excludeAttributes(['slug', 'features_count', 'users_count'])
                    ->beforeReplicaSaved(fn (Package $replica) => $replica->fill(['name' => $replica->name.' (copy)', 'slug' => null]))
                    ->after(fn (Package $replica, Package $record) => $replica->features()->sync($record->features()->pluck('features.id'))),
            ])
            ->emptyStateHeading('No packages yet')
            ->emptyStateDescription('Until you assign a package, every user gets full access to the app.');
    }
}
