@extends('site.layout')

@section('title', __('site.login.title').' · '.__('site.brand'))
@section('body_class', 'min-h-dvh')

@section('content')
<div class="grid min-h-dvh lg:grid-cols-2">
    {{-- Brand side --}}
    <aside class="lanes relative hidden overflow-hidden bg-ink p-10 text-white lg:m-3 lg:flex lg:flex-col lg:rounded-5xl xl:p-14">
        <div class="pointer-events-none absolute -right-24 -top-24 size-96 rounded-full bg-lime/15 blur-3xl"></div>
        @include('site.partials.logo', ['dark' => true])

        <div class="relative mt-auto">
            <div class="flex gap-3">
                @foreach ([['electric_rickshaw', 'bg-cng', '-6deg'], ['directions_car', 'bg-car', '0deg'], ['local_shipping', 'bg-pickup', '6deg']] as [$icon, $bg, $r])
                    <span class="grid size-16 place-items-center rounded-[1.4rem] {{ $bg }} text-white" style="transform: rotate({{ $r }})"><span class="ms text-4xl">{{ $icon }}</span></span>
                @endforeach
            </div>
            <h2 class="mt-8 text-5xl font-extrabold leading-tight tracking-tight">{{ __('site.login.side_title') }}</h2>
            <ul class="mt-8 space-y-3 text-lg text-white/75">
                @foreach (__('site.login.side_items') as $item)
                    <li class="flex items-center gap-3"><span class="grid size-8 place-items-center rounded-xl bg-lime text-ink"><span class="ms text-lg">check_circle</span></span>{{ $item }}</li>
                @endforeach
            </ul>

            {{-- A peek at the dashboard --}}
            <div class="mt-10 grid grid-cols-3 gap-3" aria-hidden="true">
                @foreach ([['group', 'text-lime'], ['monitoring', 'text-car'], ['trending_up', 'text-cng']] as [$icon, $tone])
                    <div class="rounded-3xl border border-white/10 bg-white/5 p-4">
                        <span class="ms {{ $tone }}">{{ $icon }}</span>
                        <svg viewBox="0 0 100 32" class="mt-3 h-8 w-full {{ $tone }}" fill="none"><path d="M0 26 C 15 22, 22 28, 35 18 S 60 14, 70 10 S 90 6, 100 4" stroke="currentColor" stroke-width="3" stroke-linecap="round"/></svg>
                    </div>
                @endforeach
            </div>
        </div>
    </aside>

    {{-- Form side --}}
    <main class="flex flex-col px-5 py-6 sm:px-10">
        <div class="flex items-center justify-between">
            <div class="lg:hidden">@include('site.partials.logo')</div>
            <a href="{{ route('home') }}" class="hidden items-center gap-1.5 font-semibold text-muted transition hover:text-ink lg:inline-flex"><span class="ms">arrow_back</span>{{ __('site.login.back') }}</a>
            @include('site.partials.lang')
        </div>

        <div class="mx-auto flex w-full max-w-md flex-1 flex-col justify-center py-10">
            {{-- Mobile hero, like the app's auth screen --}}
            <div class="lanes relative mb-8 overflow-hidden rounded-4xl bg-ink p-6 text-white lg:hidden">
                <div class="pointer-events-none absolute -right-12 -top-12 size-40 rounded-full bg-lime/20"></div>
                <div class="flex gap-2">
                    @foreach ([['electric_rickshaw', 'bg-cng'], ['directions_car', 'bg-car'], ['local_shipping', 'bg-pickup']] as [$icon, $bg])
                        <span class="grid size-11 place-items-center rounded-2xl {{ $bg }}"><span class="ms">{{ $icon }}</span></span>
                    @endforeach
                </div>
                <p class="mt-5 text-sm font-bold text-lime">{{ __('site.login.title') }}</p>
                <h1 class="mt-1 text-3xl font-extrabold">{{ __('site.login.heading') }}</h1>
            </div>

            <div class="hidden lg:block">
                <span class="kicker"><span class="ms text-base">admin_panel_settings</span>{{ __('site.login.title') }}</span>
                <h1 class="mt-5 text-4xl font-extrabold tracking-tight">{{ __('site.login.heading') }}</h1>
            </div>
            <p class="mt-3 text-muted">{{ __('site.login.sub') }}</p>

            @if ($errors->any())
                <div class="mt-6 flex items-center gap-3 rounded-2xl bg-expense/10 p-4 font-semibold text-expense" role="alert">
                    <span class="ms">error</span>{{ $errors->first() }}
                </div>
            @endif

            <form method="POST" action="{{ route('login.attempt') }}" class="mt-6 space-y-4">
                @csrf
                <label class="block">
                    <span class="mb-1.5 block text-sm font-bold">{{ __('site.login.email') }}</span>
                    <span class="relative block">
                        <span class="ms pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-muted">mail</span>
                        <input type="email" name="email" value="{{ old('email') }}" required autofocus autocomplete="username" class="field" placeholder="name@example.com">
                    </span>
                </label>
                <label class="block">
                    <span class="mb-1.5 block text-sm font-bold">{{ __('site.login.password') }}</span>
                    <span class="relative block">
                        <span class="ms pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-muted">lock</span>
                        <input id="password" type="password" name="password" required autocomplete="current-password" class="field pr-12" placeholder="••••••••">
                        <button type="button" data-reveal-password="password" class="absolute right-2 top-1/2 grid size-10 -translate-y-1/2 place-items-center rounded-xl text-muted hover:bg-paper-2" aria-label="Show password"><span class="ms">visibility</span></button>
                    </span>
                </label>
                <label class="flex cursor-pointer items-center gap-3 select-none">
                    <input type="checkbox" name="remember" value="1" class="size-5 rounded-md accent-ink" @checked(old('remember'))>
                    <span class="font-semibold">{{ __('site.login.remember') }}</span>
                </label>
                <button type="submit" class="btn-lime w-full !py-4 text-lg">{{ __('site.login.submit') }}<span class="ms">arrow_forward</span></button>
            </form>

            <a href="{{ is_file(public_path('app/index.html')) ? '/app/' : route('home') }}" class="mt-8 flex items-center justify-between rounded-3xl border border-line bg-white p-4 transition hover:border-ink">
                <span class="flex items-center gap-3 font-semibold"><span class="grid size-10 place-items-center rounded-2xl bg-lime"><span class="ms">smartphone</span></span>{{ __('site.login.app_user') }}</span>
                <span class="ms text-muted">arrow_forward</span>
            </a>
        </div>

        <p class="text-center text-sm text-muted">© {{ site_digits(date('Y')) }} {{ __('site.brand') }}</p>
    </main>
</div>
@endsection
