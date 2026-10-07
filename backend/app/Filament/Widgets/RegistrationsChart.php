<?php

namespace App\Filament\Widgets;

use App\Services\Analytics;
use Filament\Widgets\ChartWidget;

class RegistrationsChart extends ChartWidget
{
    protected static ?int $sort = 2;

    protected ?string $heading = 'New registrations';

    protected ?string $description = 'Users who signed up from the app';

    protected int|string|array $columnSpan = ['md' => 2, 'xl' => 2];

    protected ?string $maxHeight = '260px';

    public ?string $filter = '30';

    protected function getFilters(): ?array
    {
        return ['7' => 'Last 7 days', '30' => 'Last 30 days', '90' => 'Last 90 days'];
    }

    protected function getData(): array
    {
        $days = in_array($this->filter, ['7', '30', '90'], true) ? (int) $this->filter : 30;
        $signups = Analytics::signupsPerDay($days);
        $active = Analytics::activeUsersPerDay($days);

        return [
            'datasets' => [
                [
                    'label' => 'Registrations',
                    'data' => array_values($signups),
                    'backgroundColor' => '#84cc16',
                    'borderRadius' => 4,
                    'yAxisID' => 'y',
                    'order' => 2,
                ],
                [
                    'type' => 'line',
                    'label' => 'Active users',
                    'data' => array_values($active),
                    'borderColor' => '#38bdf8',
                    'backgroundColor' => 'transparent',
                    'borderDash' => [5, 4],
                    'tension' => 0.35,
                    'pointRadius' => 0,
                    'yAxisID' => 'y1',
                    'order' => 1,
                ],
            ],
            'labels' => Analytics::labels($signups),
        ];
    }

    protected function getOptions(): array
    {
        return [
            'plugins' => ['legend' => ['position' => 'bottom']],
            'scales' => [
                'y' => ['beginAtZero' => true, 'ticks' => ['precision' => 0], 'title' => ['display' => true, 'text' => 'Registrations']],
                'y1' => ['beginAtZero' => true, 'position' => 'right', 'grid' => ['drawOnChartArea' => false], 'ticks' => ['precision' => 0], 'title' => ['display' => true, 'text' => 'Active users']],
            ],
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
