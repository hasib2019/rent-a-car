<?php

namespace App\Filament\Resources\Users\Pages;

use App\Filament\Resources\Users\UserResource;
use App\Models\User;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Illuminate\Database\Eloquent\Builder;

class ListUsers extends ListRecords
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()->label('Add user')];
    }

    public function getTabs(): array
    {
        return [
            'all' => Tab::make('All')->badge(User::count()),
            'today' => Tab::make('New today')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('created_at', '>=', now()->startOfDay()))
                ->badge(User::where('created_at', '>=', now()->startOfDay())->count()),
            'online' => Tab::make('Online now')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('last_seen_at', '>=', now()->subMinutes(15))),
            'suspended' => Tab::make('Suspended')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', User::STATUS_SUSPENDED))
                ->badgeColor('danger')
                ->badge(User::where('status', User::STATUS_SUSPENDED)->count() ?: null),
        ];
    }
}
