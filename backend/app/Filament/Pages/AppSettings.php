<?php

namespace App\Filament\Pages;

use App\Models\AppSetting;
use App\Models\Package;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\Actions;
use Filament\Schemas\Components\EmbeddedSchema;
use Filament\Schemas\Components\Form;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use UnitEnum;

/**
 * Runtime switches the app reads from /api/v1/config.
 *
 * @property-read Schema $form
 */
class AppSettings extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedAdjustmentsHorizontal;

    protected static string|UnitEnum|null $navigationGroup = 'System';

    protected static ?string $navigationLabel = 'App settings';

    protected static ?int $navigationSort = 1;

    protected static ?string $title = 'App settings';

    /** @var array<string, mixed> */
    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill(AppSetting::values());
    }

    public function form(Schema $schema): Schema
    {
        return $schema->statePath('data')->columns(2)->components([
            Section::make('Access for users without a package')->icon(Heroicon::OutlinedKey)->columnSpanFull()
                ->description('Users with a running package always get exactly what the package includes.')
                ->schema([
                    Select::make('no_package_access')->label('Users without a package get')
                        ->options(fn () => ['full' => 'Full access to everything'] + Package::orderBy('sort_order')->pluck('name', 'id')->mapWithKeys(fn ($n, $id) => [(string) $id => 'Features of “'.$n.'”'])->all())
                        ->selectablePlaceholder(false)->required(),
                    Toggle::make('registration_open')->label('Allow new registrations from the app'),
                ]),
            Section::make('Support contacts')->icon(Heroicon::OutlinedLifebuoy)->description('Shown in the app when a feature is locked or the account is suspended.')->schema([
                TextInput::make('support_phone')->tel()->placeholder('01XXXXXXXXX'),
                TextInput::make('support_whatsapp')->label('WhatsApp')->tel(),
                TextInput::make('support_email')->email(),
            ]),
            Section::make('App version')->icon(Heroicon::OutlinedDevicePhoneMobile)->schema([
                TextInput::make('latest_app_version')->placeholder('1.0.0')->regex('/^\d+\.\d+\.\d+$/'),
                TextInput::make('min_app_version')->label('Minimum supported version')->placeholder('1.0.0')->regex('/^\d+\.\d+\.\d+$/')
                    ->helperText('Older apps are asked to update.'),
                Toggle::make('force_update')->label('Block older versions until they update'),
                TextInput::make('update_url')->label('Update link')->url()->placeholder('https://play.google.com/store/apps/details?id=…'),
            ]),
            Section::make('Maintenance')->icon(Heroicon::OutlinedWrenchScrewdriver)->columnSpanFull()->schema([
                Toggle::make('maintenance_mode')->label('Pause the API (login, registration and sync)')
                    ->helperText('The app keeps working offline; only server features stop.'),
                Textarea::make('maintenance_message')->rows(2)->placeholder('আমরা কিছুক্ষণের জন্য সার্ভারের কাজ করছি…'),
            ]),
        ]);
    }

    public function content(Schema $schema): Schema
    {
        return $schema->components([
            Form::make([EmbeddedSchema::make('form')])
                ->id('form')
                ->livewireSubmitHandler('save')
                ->footer([
                    Actions::make([
                        Action::make('save')->label('Save settings')->submit('save')->keyBindings(['mod+s']),
                    ]),
                ]),
        ]);
    }

    public function save(): void
    {
        $data = $this->form->getState();
        AppSetting::put($data);
        Notification::make()->title('Settings saved')->success()->send();
    }
}
