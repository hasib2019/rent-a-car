<?php

namespace App\Filament\Resources\Users\RelationManagers;

use App\Models\ScreenView;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class ScreenViewsRelationManager extends RelationManager
{
    protected static string $relationship = 'screenViews';

    protected static ?string $title = 'Screen activity';

    protected static string|\BackedEnum|null $icon = Heroicon::OutlinedCursorArrowRays;

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('viewed_at', 'desc')
            ->columns([
                TextColumn::make('screen')->formatStateUsing(fn (string $state) => ScreenView::label($state))
                    ->description(fn (ScreenView $r) => $r->screen),
                TextColumn::make('viewed_at')->dateTime('j M Y, g:i:s a')->description(fn (ScreenView $r) => $r->viewed_at->diffForHumans()),
                TextColumn::make('platform')->badge()->color('gray'),
                TextColumn::make('app_version')->label('Version'),
                TextColumn::make('session_id')->label('Session')->limit(8)->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('screen')->options(fn () => collect(config('screens'))->all())->searchable(),
            ]);
    }
}
