<?php

namespace App\Filament\Resources\Subscriptions;

use App\Filament\Resources\Subscriptions\Pages\ManageSubscriptions;
use App\Filament\Resources\Users\UserResource;
use App\Models\Package;
use App\Models\Subscription;
use App\Services\SubscriptionManager;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class SubscriptionResource extends Resource
{
    protected static ?string $model = Subscription::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedReceiptPercent;

    protected static string|UnitEnum|null $navigationGroup = 'Packages';

    protected static ?string $navigationLabel = 'Subscriptions';

    protected static ?int $navigationSort = 3;

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            DateTimePicker::make('starts_at')->required()->seconds(false),
            DateTimePicker::make('ends_at')->seconds(false)->helperText('Empty = never expires'),
            TextInput::make('amount')->numeric()->prefix('৳'),
            Select::make('payment_method')->options(['cash' => 'Cash', 'bkash' => 'bKash', 'nagad' => 'Nagad', 'rocket' => 'Rocket', 'bank' => 'Bank transfer', 'free' => 'Free / promo']),
            TextInput::make('payment_ref')->label('Transaction ID'),
            Select::make('status')->options(['active' => 'Active', 'cancelled' => 'Cancelled'])->required(),
            Textarea::make('note')->columnSpanFull(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->modifyQueryUsing(fn (Builder $query) => $query->with(['user', 'package', 'createdBy']))
            ->columns([
                TextColumn::make('user.name')->label('User')->searchable()->weight('semibold')
                    ->description(fn (Subscription $r) => $r->user?->phone)
                    ->url(fn (Subscription $r) => $r->user ? UserResource::getUrl('view', ['record' => $r->user]) : null),
                TextColumn::make('package.name')->badge()->color('primary'),
                TextColumn::make('state')->badge()
                    ->state(fn (Subscription $r) => $r->state())
                    ->color(fn (string $state) => match ($state) {
                        'running' => 'success', 'scheduled' => 'info', 'expired' => 'gray', default => 'danger',
                    }),
                TextColumn::make('starts_at')->dateTime('j M Y')->sortable(),
                TextColumn::make('ends_at')->dateTime('j M Y')->sortable()->placeholder('Never')
                    ->description(fn (Subscription $r) => $r->ends_at && $r->ends_at->isFuture() ? $r->ends_at->diffForHumans() : null),
                TextColumn::make('amount')->money('BDT')->sortable()->summarize(\Filament\Tables\Columns\Summarizers\Sum::make()->money('BDT')),
                TextColumn::make('payment_method')->badge()->color('gray')->placeholder('—'),
                TextColumn::make('payment_ref')->label('Txn ID')->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('createdBy.name')->label('Assigned by')->toggleable(),
            ])
            ->filters([
                SelectFilter::make('package_id')->label('Package')->options(fn () => Package::pluck('name', 'id')),
                SelectFilter::make('state')->options(['running' => 'Running', 'expired' => 'Expired', 'scheduled' => 'Scheduled', 'cancelled' => 'Cancelled'])
                    ->query(fn (Builder $query, array $data) => match ($data['value'] ?? null) {
                        'running' => $query->current(),
                        'expired' => $query->where('status', 'active')->whereNotNull('ends_at')->where('ends_at', '<=', now()),
                        'scheduled' => $query->where('status', 'active')->where('starts_at', '>', now()),
                        'cancelled' => $query->where('status', 'cancelled'),
                        default => $query,
                    }),
                SelectFilter::make('payment_method')->options(['cash' => 'Cash', 'bkash' => 'bKash', 'nagad' => 'Nagad', 'rocket' => 'Rocket', 'bank' => 'Bank transfer', 'free' => 'Free / promo']),
            ])
            ->recordActions([
                EditAction::make(),
                Action::make('cancel')->icon(Heroicon::OutlinedXCircle)->color('danger')->requiresConfirmation()
                    ->visible(fn (Subscription $r) => in_array($r->state(), ['running', 'scheduled'], true))
                    ->action(fn (Subscription $r) => app(SubscriptionManager::class)->cancel($r)),
            ])
            ->emptyStateHeading('No subscriptions yet')
            ->emptyStateDescription('Assign a package from a user\'s page. Users without one have full access.');
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function getPages(): array
    {
        return ['index' => ManageSubscriptions::route('/')];
    }
}
