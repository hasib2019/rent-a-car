<?php

namespace App\Filament\Resources\Features;

use App\Filament\Resources\Features\Pages\ManageFeatures;
use App\Models\Feature;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use UnitEnum;

/**
 * Features come from config/features.php and must match keys in the app,
 * so admins can rename / describe them but not invent new keys here.
 */
class FeatureResource extends Resource
{
    protected static ?string $model = Feature::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedSquares2x2;

    protected static string|UnitEnum|null $navigationGroup = 'Packages';

    protected static ?int $navigationSort = 2;

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('key')->disabled()->helperText('Used by the app — cannot be changed.'),
            Select::make('group')->options(['core' => 'Core', 'business' => 'Business', 'maintenance' => 'Maintenance', 'insights' => 'Insights', 'data' => 'Data'])->required(),
            TextInput::make('name')->required(),
            TextInput::make('name_bn')->label('Name (Bangla)'),
            TextInput::make('description')->columnSpanFull(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('sort_order')
            ->reorderable('sort_order')
            ->columns([
                TextColumn::make('name')->weight('semibold')->description(fn (Feature $r) => $r->name_bn),
                TextColumn::make('key')->fontFamily('mono')->copyable()->color('gray'),
                TextColumn::make('group')->badge(),
                TextColumn::make('description')->wrap()->color('gray'),
                TextColumn::make('packages_count')->counts('packages')->label('In packages')->badge()->color('primary'),
            ])
            ->recordActions([EditAction::make()]);
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function getPages(): array
    {
        return ['index' => ManageFeatures::route('/')];
    }
}
