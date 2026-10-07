<?php

namespace App\Filament\Resources\Users\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class DevicesRelationManager extends RelationManager
{
    protected static string $relationship = 'devices';

    protected static string|\BackedEnum|null $icon = Heroicon::OutlinedDevicePhoneMobile;

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('model')->placeholder('Unknown')->weight('semibold'),
                TextColumn::make('platform')->badge()->color('gray'),
                TextColumn::make('os_version')->label('OS'),
                TextColumn::make('app_version')->label('App'),
                TextColumn::make('last_seen_at')->since()->label('Last seen'),
                TextColumn::make('created_at')->dateTime('j M Y')->label('First seen'),
            ]);
    }
}
