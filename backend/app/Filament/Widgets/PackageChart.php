<?php

namespace App\Filament\Widgets;

use App\Services\Analytics;
use Filament\Widgets\ChartWidget;

class PackageChart extends ChartWidget
{
    protected static ?int $sort = 5;

    protected ?string $heading = 'Users by package';

    protected ?string $description = 'Users without a package get full access';

    protected ?string $maxHeight = '260px';

    protected function getData(): array
    {
        $data = Analytics::packageDistribution();
        $palette = ['#d4d4d8', '#84cc16', '#38bdf8', '#f59e0b', '#a78bfa', '#f43f5e', '#14b8a6'];

        return [
            'datasets' => [[
                'data' => array_values($data),
                'backgroundColor' => array_slice(array_merge($palette, $palette), 0, count($data)),
                'borderWidth' => 0,
            ]],
            'labels' => array_keys($data),
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
