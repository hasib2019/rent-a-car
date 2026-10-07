<?php

if (! function_exists('site_digits')) {
    /** Bangla numerals on the Bangla site, Latin otherwise. */
    function site_digits(string|int|float $value): string
    {
        $value = (string) $value;

        return app()->getLocale() === 'bn'
            ? strtr($value, ['0' => '০', '1' => '১', '2' => '২', '3' => '৩', '4' => '৪', '5' => '৫', '6' => '৬', '7' => '৭', '8' => '৮', '9' => '৯'])
            : $value;
    }
}
