<?php

namespace App\Filament\Resources\Users\Pages;

use App\Filament\Resources\Users\UserResource;
use App\Filament\Support\AssignPackageAction;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Actions\ActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Icons\Heroicon;

class ViewUser extends ViewRecord
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [
            AssignPackageAction::make(),
            EditAction::make(),
            ActionGroup::make([
                Action::make('toggleStatus')
                    ->label(fn (User $record) => $record->isActive() ? 'Suspend account' : 'Re-activate account')
                    ->icon(fn (User $record) => $record->isActive() ? Heroicon::OutlinedNoSymbol : Heroicon::OutlinedCheckCircle)
                    ->color(fn (User $record) => $record->isActive() ? 'danger' : 'success')
                    ->requiresConfirmation()
                    ->modalDescription(fn (User $record) => $record->isActive()
                        ? 'The user is signed out everywhere and cannot log in until re-activated. Their data on the phone stays.'
                        : 'The user can log in again.')
                    ->action(function (User $record) {
                        $suspend = $record->isActive();
                        $record->update(['status' => $suspend ? User::STATUS_SUSPENDED : User::STATUS_ACTIVE]);
                        if ($suspend) {
                            $record->tokens()->delete();
                        }
                        Notification::make()->title($suspend ? 'Account suspended' : 'Account re-activated')->success()->send();
                    }),
                Action::make('logoutEverywhere')
                    ->label('Sign out of all devices')
                    ->icon(Heroicon::OutlinedArrowRightStartOnRectangle)
                    ->requiresConfirmation()
                    ->action(function (User $record) {
                        $count = $record->tokens()->count();
                        $record->tokens()->delete();
                        Notification::make()->title("Signed out of $count session(s)")->success()->send();
                    }),
                DeleteAction::make()->modalDescription('Deletes the account permanently. Screen analytics are kept without the user.'),
            ])->icon(Heroicon::EllipsisVertical)->button()->label('More'),
        ];
    }
}
