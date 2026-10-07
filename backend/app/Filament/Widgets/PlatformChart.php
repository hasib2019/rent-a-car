<?php

namespace App\Filament\Widgets;

use App\Services\Analytics;
use Filament\Widgets\ChartWidget;

class PlatformChart extends ChartWidget
{
    protected static ?int $sort = 3;

    protected ?string $heading = 'Platforms';

    protected ?string $description = 'Where users last opened the app';

    protected ?string $maxHeight = '260px';

    protected function getData(): array
    {
        $data = Analytics::platforms();
        $colors = ['android' => '#84cc16', 'ios' => '#a1a1aa', 'web' => '#38bdf8', 'unknown' => '#e4e4e7'];

        return [
            'datasets' => [[
                'data' => array_values($data),
                'backgroundColor' => array_map(fn ($k) => $colors[$k] ?? '#f59e0b', array_keys($data)),
                'borderWidth' => 0,
            ]],
            'labels' => array_map(fn ($k) => ['android' => 'Android', 'ios' => 'iOS', 'web' => 'Web'][$k] ?? ucfirst($k), array_keys($data)),
        ];
    }

    protected function getOptions(): array
    {
        return ['cutout' => '68%', 'plugins' => ['legend' => ['position' => 'bottom']], 'scales' => ['x' => ['display' => false], 'y' => ['display' => false]]];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }
}
