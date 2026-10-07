<?php

namespace App\Filament\Resources\Admins;

use App\Filament\Resources\Admins\Pages\ManageAdmins;
use App\Models\Admin;
use BackedEnum;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use UnitEnum;

class AdminResource extends Resource
{
    protected static ?string $model = Admin::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedShieldCheck;

    protected static string|UnitEnum|null $navigationGroup = 'System';

    protected static ?string $navigationLabel = 'Admins';

    protected static ?int $navigationSort = 2;

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            TextInput::make('name')->required(),
            TextInput::make('email')->email()->required()->unique(ignoreRecord: true),
            TextInput::make('password')->password()->revealable()
                ->required(fn (string $operation) => $operation === 'create')
                ->minLength(8)
                ->dehydrated(fn ($state) => filled($state))
                ->helperText(fn (string $operation) => $operation === 'edit' ? 'Leave empty to keep the current password' : null),
            Toggle::make('is_active')->label('Can sign in')->default(true)
                ->disabled(fn (?Admin $record) => $record?->is(auth('admin')->user())),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->weight('semibold'),
                TextColumn::make('email')->copyable(),
                IconColumn::make('is_active')->boolean()->label('Active'),
                TextColumn::make('last_login_at')->since()->placeholder('Never'),
                TextColumn::make('created_at')->dateTime('j M Y'),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make()->hidden(fn (Admin $record) => $record->is(auth('admin')->user())),
            ]);
    }

    public static function getPages(): array
    {
        return ['index' => ManageAdmins::route('/')];
    }
}
