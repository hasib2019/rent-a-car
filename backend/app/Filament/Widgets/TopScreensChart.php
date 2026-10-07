<?php

namespace App\Filament\Widgets;

use App\Services\Analytics;
use Filament\Widgets\ChartWidget;

class TopScreensChart extends ChartWidget
{
    protected static ?int $sort = 4;

    protected ?string $heading = 'Most used screens';

    protected ?string $description = 'Screen views and unique users';

    protected int|string|array $columnSpan = ['md' => 2, 'xl' => 2];

    protected ?string $maxHeight = '320px';

    public ?string $filter = '30';

    protected function getFilters(): ?array
    {
        return ['1' => 'Today', '7' => 'Last 7 days', '30' => 'Last 30 days', '90' => 'Last 90 days'];
    }

    protected function getData(): array
    {
        $days = in_array($this->filter, ['1', '7', '30', '90'], true) ? (int) $this->filter : 30;
        $rows = Analytics::screens(now()->subDays($days - 1)->startOfDay())->take(10);

        return [
            'datasets' => [
                ['label' => 'Views', 'data' => $rows->pluck('views')->all(), 'backgroundColor' => '#84cc16', 'borderRadius' => 6],
                ['label' => 'Unique users', 'data' => $rows->pluck('users')->all(), 'backgroundColor' => '#3f3f46', 'borderRadius' => 6],
            ],
            'labels' => $rows->pluck('label')->all(),
        ];
    }

    protected function getOptions(): array
    {
        return ['indexAxis' => 'y', 'plugins' => ['legend' => ['position' => 'bottom']]];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
