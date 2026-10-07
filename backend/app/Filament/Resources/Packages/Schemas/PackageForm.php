<?php

namespace App\Filament\Resources\Packages\Schemas;

use App\Models\Feature;
use Filament\Forms\Components\CheckboxList;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;

class PackageForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->columns(3)->components([
            Section::make('Package')->icon(Heroicon::OutlinedGift)->columns(2)->columnSpan(2)->schema([
                TextInput::make('name')->required()->maxLength(80)->placeholder('e.g. Basic, Pro, Fleet'),
                TextInput::make('price')->label('Price')->numeric()->prefix('৳')->default(0)->required(),
                TextInput::make('duration_days')->label('Duration (days)')->numeric()->minValue(1)
                    ->helperText('Empty = never expires'),
                TextInput::make('sort_order')->numeric()->default(0),
                Textarea::make('description')->rows(2)->columnSpanFull()
                    ->helperText('For admins only — packages are not shown in the app.'),
                Toggle::make('is_active')->label('Can be assigned')->default(true),
            ]),
            Section::make('Limits')->icon(Heroicon::OutlinedAdjustmentsHorizontal)->columnSpan(1)
                ->description('Empty = unlimited')
                ->schema([
                    TextInput::make('max_vehicles')->label('Max vehicles')->numeric()->minValue(0),
                    TextInput::make('max_drivers')->label('Max drivers')->numeric()->minValue(0),
                ]),
            Section::make('Features')->icon(Heroicon::OutlinedSquares2x2)->columnSpanFull()
                ->description('What users on this package can use in the app. Anything left unticked is locked for them.')
                ->schema([
                    CheckboxList::make('features')
                        ->hiddenLabel()
                        ->relationship('features', 'name', fn ($query) => $query->orderBy('sort_order'))
                        ->getOptionLabelFromRecordUsing(fn (Feature $f) => $f->name.($f->name_bn ? ' · '.$f->name_bn : ''))
                        ->descriptions(fn () => Feature::orderBy('sort_order')->pluck('description', 'id')->all())
                        ->bulkToggleable()
                        ->columns(['md' => 2, 'xl' => 3])
                        ->gridDirection('row'),
                ]),
        ]);
    }
}
