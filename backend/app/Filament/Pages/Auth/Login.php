<?php

namespace App\Filament\Pages\Auth;

use Filament\Auth\Pages\Login as BaseLogin;

/** The panel's login lives on the website (/login); send people there. */
class Login extends BaseLogin
{
    public function mount(): void
    {
        $this->redirect(route('login'));
    }
}
