<?php

namespace App\Filament\Resources\Users\RelationManagers;

use App\Filament\Support\AssignPackageAction;
use App\Models\Subscription;
use App\Services\SubscriptionManager;
use Filament\Actions\Action;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class SubscriptionsRelationManager extends RelationManager
{
    protected static string $relationship = 'subscriptions';

    protected static ?string $title = 'Packages';

    protected static string|\BackedEnum|null $icon = Heroicon::OutlinedGift;

    public function isReadOnly(): bool
    {
        return false;
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('starts_at', 'desc')
            ->columns([
                TextColumn::make('package.name')->weight('semibold'),
                TextColumn::make('state')->badge()
                    ->state(fn (Subscription $r) => $r->state())
                    ->color(fn (string $state) => match ($state) {
                        'running' => 'success', 'scheduled' => 'info', 'expired' => 'gray', default => 'danger',
                    }),
                TextColumn::make('starts_at')->dateTime('j M Y'),
                TextColumn::make('ends_at')->dateTime('j M Y')->placeholder('Never'),
                TextColumn::make('amount')->money('BDT'),
                TextColumn::make('payment_method')->badge()->color('gray')->placeholder('—'),
                TextColumn::make('createdBy.name')->label('By')->placeholder('—'),
            ])
            ->headerActions([
                AssignPackageAction::make(user: fn () => $this->getOwnerRecord()),
            ])
            ->recordActions([
                Action::make('cancel')->icon(Heroicon::OutlinedXCircle)->color('danger')
                    ->visible(fn (Subscription $r) => in_array($r->state(), ['running', 'scheduled'], true))
                    ->requiresConfirmation()
                    ->modalDescription('The user goes back to full access (or the fallback set in Settings).')
                    ->action(fn (Subscription $r) => app(SubscriptionManager::class)->cancel($r)),
            ])
            ->emptyStateHeading('No package')
            ->emptyStateDescription('This user has full access to every feature.');
    }
}
