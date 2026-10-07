@php($admin = auth('admin')->check())
<header data-nav class="fixed inset-x-0 top-0 z-50 transition-all duration-300 [&.is-scrolled]:border-b [&.is-scrolled]:border-line/70 [&.is-scrolled]:bg-paper/85 [&.is-scrolled]:backdrop-blur-xl">
    <nav class="mx-auto flex h-18 max-w-7xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8" aria-label="Main">
        @include('site.partials.logo')

        <div class="hidden items-center gap-1 lg:flex">
            @foreach (['features', 'how', 'screens', 'faq'] as $id)
                <a href="{{ route('home') }}#{{ $id }}" class="rounded-full px-4 py-2 font-semibold text-ink/70 transition hover:bg-paper-2 hover:text-ink">{{ __("site.nav.$id") }}</a>
            @endforeach
        </div>

        <div class="flex items-center gap-2">
            <div class="hidden sm:block">@include('site.partials.lang')</div>
            <a href="{{ $admin ? url('/admin') : route('login') }}" class="hidden items-center gap-1.5 rounded-2xl bg-ink px-4 py-2.5 text-sm font-bold text-paper transition hover:bg-ink-2 sm:inline-flex">
                <span class="ms text-lime text-[1.2em]">{{ $admin ? 'admin_panel_settings' : 'login' }}</span>{{ $admin ? __('site.nav.dashboard') : __('site.nav.login') }}
            </a>
            <button type="button" data-menu-toggle aria-expanded="false" aria-label="{{ __('site.nav.menu') }}" class="grid size-11 place-items-center rounded-2xl bg-ink text-paper lg:hidden">
                <span class="ms">menu</span>
            </button>
        </div>
    </nav>

    {{-- Mobile menu --}}
    <div data-menu class="lanes fixed inset-0 z-50 hidden overflow-y-auto bg-ink px-5 pb-10 pt-4 text-white lg:hidden">
        <div class="flex h-14 items-center justify-between">
            @include('site.partials.logo', ['dark' => true])
            <button type="button" data-menu-toggle aria-label="Close" class="grid size-11 place-items-center rounded-2xl bg-white/10"><span class="ms">close</span></button>
        </div>
        <div class="mt-8 flex flex-col gap-2">
            @foreach (['features', 'how', 'screens', 'faq'] as $i => $id)
                <a href="{{ route('home') }}#{{ $id }}" class="flex items-center justify-between rounded-3xl bg-white/5 px-5 py-4 text-2xl font-extrabold">
                    {{ __("site.nav.$id") }}<span class="ms text-lime">arrow_forward</span>
                </a>
            @endforeach
        </div>
        <div class="mt-8 flex flex-col gap-3">
            <a href="{{ route('download.android') }}" class="btn-lime"><span class="ms">android</span>{{ __('site.hero.download') }}</a>
            @if (! empty($webReady))
                <a href="/app/" class="btn-ghost"><span class="ms">language</span>{{ __('site.hero.web') }}</a>
            @endif
            <a href="{{ $admin ? url('/admin') : route('login') }}" class="btn-ghost"><span class="ms">login</span>{{ $admin ? __('site.nav.dashboard') : __('site.nav.login') }}</a>
            <div class="mt-4 flex justify-center">@include('site.partials.lang', ['dark' => true])</div>
        </div>
    </div>
</header>
