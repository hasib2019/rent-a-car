<?php

namespace App\Filament\Support;

use App\Models\Package;
use App\Models\User;
use App\Services\SubscriptionManager;
use Filament\Actions\Action;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Components\Utilities\Set;
use Filament\Support\Icons\Heroicon;
use Illuminate\Support\Carbon;

/** "Assign package" modal used on the user page and the users table. */
class AssignPackageAction
{
    public static function make(string $name = 'assignPackage', ?\Closure $user = null): Action
    {
        return Action::make($name)
            ->label('Assign package')
            ->icon(Heroicon::OutlinedGift)
            ->color('primary')
            ->modalHeading('Assign a package')
            ->modalDescription('The user\'s current package (if any) ends when the new one starts. Packages are never shown in the app — only the features they unlock.')
            ->schema([
                Select::make('package_id')
                    ->label('Package')
                    ->options(Package::query()->where('is_active', true)->orderBy('sort_order')->pluck('name', 'id'))
                    ->required()
                    ->live()
                    ->afterStateUpdated(function (?string $state, Get $get, Set $set) {
                        $package = Package::find($state);
                        if (! $package) {
                            return;
                        }
                        $set('amount', $package->price);
                        $starts = Carbon::parse($get('starts_at') ?: now());
                        $set('ends_at', $package->duration_days ? $starts->addDays($package->duration_days)->toDateTimeString() : null);
                    }),
                Grid::make(2)->schema([
                    DateTimePicker::make('starts_at')->label('Starts')->default(now())->required()->seconds(false),
                    DateTimePicker::make('ends_at')->label('Ends')->helperText('Empty = never expires')->seconds(false)->after('starts_at'),
                    TextInput::make('amount')->label('Amount paid')->numeric()->prefix('৳')->default(0),
                    Select::make('payment_method')->options([
                        'cash' => 'Cash', 'bkash' => 'bKash', 'nagad' => 'Nagad', 'rocket' => 'Rocket', 'bank' => 'Bank transfer', 'free' => 'Free / promo',
                    ]),
                ]),
                TextInput::make('payment_ref')->label('Transaction ID / reference')->maxLength(100),
                Textarea::make('note')->rows(2),
            ])
            ->action(function (array $data, $record) use ($user) {
                /** @var User $target */
                $target = $user ? $user($record) : $record;
                app(SubscriptionManager::class)->assign($target, Package::findOrFail($data['package_id']), $data, auth('admin')->id());
                Notification::make()->title('Package assigned to '.$target->name)->success()->send();
            });
    }
}
