<?php

namespace App\Filament\Pages;

use App\Filament\Resources\ScreenViews\ScreenViewResource;
use App\Filament\Widgets\TopScreensChart;
use App\Services\Analytics;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Pages\Page;
use Filament\Schemas\Components\EmbeddedTable;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Table;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;
use UnitEnum;

/**
 * How many times, and by how many users, each app screen was opened.
 */
class ScreenAnalytics extends Page implements HasTable
{
    use InteractsWithTable;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedPresentationChartBar;

    protected static string|UnitEnum|null $navigationGroup = 'Analytics';

    protected static ?string $navigationLabel = 'Screen analytics';

    protected static ?int $navigationSort = 1;

    protected static ?string $title = 'Screen analytics';

    public function getSubheading(): ?string
    {
        return 'Which screens owners open, how often, and how many different users reach them.';
    }

    protected function getHeaderWidgets(): array
    {
        return [TopScreensChart::class];
    }

    public function getHeaderWidgetsColumns(): int|array
    {
        return 1;
    }

    public function content(Schema $schema): Schema
    {
        return $schema->components([EmbeddedTable::make()]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->records(function (?string $sortColumn, ?string $sortDirection, ?string $search, array $filters): Collection {
                $range = $filters['range']['range'] ?? '30';
                $from = match ($range) {
                    'today' => now()->startOfDay(),
                    '7' => now()->subDays(6)->startOfDay(),
                    '90' => now()->subDays(89)->startOfDay(),
                    'all' => null,
                    default => now()->subDays(29)->startOfDay(),
                };
                $platform = in_array($filters['range']['platform'] ?? null, ['android', 'ios', 'web'], true) ? $filters['range']['platform'] : null;

                $rows = Analytics::screens($from, null, $platform);
                $total = max(1, $rows->sum('views'));
                $rows = $rows->map(fn (array $r) => $r + [
                    'share' => round($r['views'] / $total * 100, 1),
                    'per_user' => $r['users'] ? round($r['views'] / $r['users'], 1) : 0,
                ]);

                if (filled($search)) {
                    $rows = $rows->filter(fn ($r) => Str::contains(Str::lower($r['label'].' '.$r['screen']), Str::lower($search)));
                }
                if (in_array($sortColumn, ['views', 'users', 'per_user', 'last', 'label'], true)) {
                    $rows = $rows->sortBy($sortColumn, SORT_NATURAL, $sortDirection === 'desc');
                }

                return $rows->keyBy('screen');
            })
            ->searchable()
            ->deferFilters(false)
            ->paginated(false)
            ->columns([
                TextColumn::make('label')->label('Screen')->weight('semibold')->sortable()
                    ->description(fn (array $record) => $record['screen']),
                TextColumn::make('views')->numeric()->sortable()->alignEnd(),
                TextColumn::make('users')->label('Unique users')->numeric()->sortable()->alignEnd()->color('primary')->weight('semibold'),
                TextColumn::make('per_user')->label('Views / user')->sortable()->alignEnd(),
                TextColumn::make('share')->label('Share of views')->suffix('%')->alignEnd(),
                TextColumn::make('last')->label('Last opened')->sortable()
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->diffForHumans() : '—'),
            ])
            ->filters([
                Filter::make('range')->schema([
                    Select::make('range')->label('Period')->options([
                        'today' => 'Today', '7' => 'Last 7 days', '30' => 'Last 30 days', '90' => 'Last 90 days', 'all' => 'All time',
                    ])->default('30')->selectablePlaceholder(false),
                    Select::make('platform')->options(['android' => 'Android', 'ios' => 'iOS', 'web' => 'Web'])->placeholder('All platforms'),
                ]),
            ], layout: \Filament\Tables\Enums\FiltersLayout::AboveContent)
            ->recordActions([
                Action::make('log')->label('Who opened it')->icon(Heroicon::OutlinedUsers)
                    ->url(fn (array $record) => ScreenViewResource::getUrl('index', [
                        'filters' => ['screen' => ['values' => [$record['screen']]]],
                    ])),
            ])
            ->emptyStateHeading('No screen activity yet')
            ->emptyStateDescription('Views appear here as soon as owners use the app.');
    }
}
