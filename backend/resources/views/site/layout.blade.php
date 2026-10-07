<!doctype html>
<html lang="{{ app()->getLocale() }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title>@yield('title', __('site.meta.title'))</title>
    <meta name="description" content="@yield('description', __('site.meta.description'))">
    <meta name="theme-color" content="#121418">
    <meta property="og:title" content="@yield('title', __('site.meta.title'))">
    <meta property="og:description" content="{{ __('site.meta.description') }}">
    <meta property="og:image" content="{{ asset('site/desktop.webp') }}">
    <meta property="og:type" content="website">
    <link rel="icon" type="image/png" href="{{ asset('site/icon.png') }}">
    <link rel="apple-touch-icon" href="{{ asset('site/icon.png') }}">
    <link rel="preload" href="/fonts/AnekBangla-ExtraBold.ttf" as="font" type="font/ttf" crossorigin>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="@yield('body_class')">
    @if (session('notice') || session('status'))
        <div class="fixed inset-x-0 top-20 z-[60] flex justify-center px-4" role="status">
            <div class="flex items-center gap-3 rounded-2xl bg-ink px-5 py-3 text-sm font-semibold text-paper shadow-xl">
                <span class="ms text-lime">info</span>{{ session('notice') ?? session('status') }}
            </div>
        </div>
    @endif
    @yield('content')
</body>
</html>
