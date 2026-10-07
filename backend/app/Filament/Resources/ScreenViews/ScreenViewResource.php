<?php

namespace App\Filament\Resources\ScreenViews;

use App\Filament\Resources\ScreenViews\Pages\ListScreenViews;
use App\Filament\Resources\Users\UserResource;
use App\Models\ScreenView;
use BackedEnum;
use Filament\Forms\Components\DatePicker;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

/** Raw, read-only log of every screen opened in the app. */
class ScreenViewResource extends Resource
{
    protected static ?string $model = ScreenView::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedQueueList;

    protected static string|UnitEnum|null $navigationGroup = 'Analytics';

    protected static ?string $navigationLabel = 'Activity log';

    protected static ?string $modelLabel = 'screen view';

    protected static ?int $navigationSort = 2;

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('viewed_at', 'desc')
            ->modifyQueryUsing(fn (Builder $query) => $query->with('user'))
            ->poll('30s')
            ->columns([
                TextColumn::make('user.name')->label('User')->placeholder('Deleted user')->searchable()
                    ->description(fn (ScreenView $r) => $r->user?->phone)
                    ->url(fn (ScreenView $r) => $r->user ? UserResource::getUrl('view', ['record' => $r->user]) : null),
                TextColumn::make('screen')->formatStateUsing(fn (string $state) => ScreenView::label($state))
                    ->description(fn (ScreenView $r) => $r->screen)->searchable(),
                TextColumn::make('platform')->badge()->color('gray'),
                TextColumn::make('app_version')->label('Version')->toggleable(),
                TextColumn::make('viewed_at')->label('When')->dateTime('j M Y, g:i:s a')->sortable()
                    ->description(fn (ScreenView $r) => $r->viewed_at->diffForHumans()),
            ])
            ->filters([
                SelectFilter::make('screen')->options(fn () => collect(config('screens'))->all())->searchable()->multiple(),
                SelectFilter::make('platform')->options(['android' => 'Android', 'ios' => 'iOS', 'web' => 'Web']),
                SelectFilter::make('user_id')->label('User')->relationship('user', 'name')->searchable(),
                Filter::make('viewed')->schema([
                    DatePicker::make('from'),
                    DatePicker::make('until'),
                ])->query(fn (Builder $query, array $data) => $query
                    ->when($data['from'] ?? null, fn ($q, $d) => $q->whereDate('viewed_at', '>=', $d))
                    ->when($data['until'] ?? null, fn ($q, $d) => $q->whereDate('viewed_at', '<=', $d))),
            ]);
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function getPages(): array
    {
        return ['index' => ListScreenViews::route('/')];
    }
}
