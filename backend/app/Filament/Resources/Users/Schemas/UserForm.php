<?php

namespace App\Filament\Resources\Users\Schemas;

use App\Models\User;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Hash;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            Section::make('Account')->columns(2)->schema([
                TextInput::make('name')->required()->maxLength(100),
                TextInput::make('username')->required()->maxLength(30)
                    ->regex('/^[a-z0-9_.]+$/')->unique(ignoreRecord: true)
                    ->dehydrateStateUsing(fn ($state) => strtolower(trim($state)))
                    ->helperText('Lowercase letters, numbers, _ and .'),
                TextInput::make('email')->email()->required()->unique(ignoreRecord: true)
                    ->dehydrateStateUsing(fn ($state) => strtolower(trim($state))),
                TextInput::make('phone')->tel()->required()->unique(ignoreRecord: true)
                    ->dehydrateStateUsing(fn ($state) => User::normalizePhone($state))
                    ->rule('regex:/^(\+?880)?0?1[3-9]\d{8}$/')
                    ->placeholder('01XXXXXXXXX'),
                Select::make('status')->options([
                    User::STATUS_ACTIVE => 'Active',
                    User::STATUS_SUSPENDED => 'Suspended',
                ])->default(User::STATUS_ACTIVE)->required()->native(false),
                TextInput::make('password')
                    ->password()->revealable()
                    ->label(fn (string $operation) => $operation === 'create' ? 'Password' : 'New password')
                    ->helperText(fn (string $operation) => $operation === 'create' ? 'At least 8 characters' : 'Leave empty to keep the current password')
                    ->required(fn (string $operation) => $operation === 'create')
                    ->minLength(8)
                    ->dehydrated(fn ($state) => filled($state))
                    ->dehydrateStateUsing(fn ($state) => Hash::make($state)),
            ])->columnSpanFull(),
            Section::make('Business')->columns(3)->schema([
                TextInput::make('business_name')->maxLength(120),
                TextInput::make('district')->maxLength(60),
                TextInput::make('fleet_size')->label('Vehicles')->numeric()->minValue(0),
            ])->columnSpanFull(),
            Section::make('Internal note')->schema([
                Textarea::make('admin_note')->hiddenLabel()->rows(3)->placeholder('Only admins see this'),
            ])->columnSpanFull()->collapsible(),
        ]);
    }
}
