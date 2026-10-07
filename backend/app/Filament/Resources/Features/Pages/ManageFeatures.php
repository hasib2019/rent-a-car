<?php

namespace App\Filament\Resources\Features\Pages;

use App\Filament\Resources\Features\FeatureResource;
use Filament\Resources\Pages\ManageRecords;

class ManageFeatures extends ManageRecords
{
    protected static string $resource = FeatureResource::class;

    public function getSubheading(): ?string
    {
        return 'Capabilities of the app that packages can unlock. Add new ones in config/features.php together with the app code.';
    }
}
