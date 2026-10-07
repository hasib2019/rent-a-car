<?php

namespace App\Filament\Widgets;

use App\Filament\Resources\Users\UserResource;
use App\Models\User;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class LatestUsers extends TableWidget
{
    protected static ?int $sort = 6;

    protected int|string|array $columnSpan = 'full';

    protected static ?string $heading = 'Latest registrations';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn () => User::query()->with('activeSubscription.package')->withCount('screenViews')->latest()->limit(8))
            ->paginated(false)
            ->recordUrl(fn (User $record) => UserResource::getUrl('view', ['record' => $record]))
            ->columns([
                TextColumn::make('name')->weight('semibold')->description(fn (User $r) => '@'.$r->username),
                TextColumn::make('phone'),
                TextColumn::make('district')->placeholder('—'),
                TextColumn::make('signup_platform')->label('Signed up on')->badge()->color('gray'),
                TextColumn::make('screen_views_count')->label('Screen views')->numeric(),
                TextColumn::make('created_at')->label('Joined')->since(),
            ]);
    }
}
