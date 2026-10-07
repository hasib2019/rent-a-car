@extends('site.layout')

@php
    $bn = app()->getLocale() === 'bn';
    $types = [
        ['electric_rickshaw', 'bg-cng'], ['directions_car', 'bg-car'], ['local_shipping', 'bg-pickup'],
        ['airport_shuttle', 'bg-micro'], ['directions_bus', 'bg-bus'], ['two_wheeler', 'bg-bike'],
    ];
    $typeNames = __('site.types.items');
    $m = __('site.features.mini');
@endphp

@section('content')
@include('site.partials.nav')

<main>
    {{-- ───────────────────────── Hero ───────────────────────── --}}
    <section class="px-3 pt-22 sm:px-4 lg:pt-24">
        <div class="lanes relative mx-auto max-w-[88rem] overflow-hidden rounded-[2rem] bg-ink text-white sm:rounded-5xl">
            <div class="pointer-events-none absolute -right-24 -top-24 size-[28rem] rounded-full bg-lime/15 blur-3xl"></div>
            <div class="pointer-events-none absolute -bottom-40 -left-24 size-[26rem] rounded-full bg-car/15 blur-3xl"></div>

            <div class="relative mx-auto grid max-w-7xl items-center gap-12 px-5 pb-0 pt-12 sm:px-8 sm:pt-16 lg:grid-cols-12 lg:gap-6 lg:px-12 lg:pb-16 lg:pt-20">
                <div class="lg:col-span-6 xl:col-span-6">
                    <p class="reveal inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3.5 py-1.5 text-sm font-semibold text-white/80">
                        <span class="size-2 animate-pulse rounded-full bg-lime"></span>{{ __('site.hero.badge') }}
                    </p>
                    <h1 class="reveal mt-6 text-[2.6rem] font-extrabold leading-[1.08] tracking-tight sm:text-6xl lg:text-[4.1rem]">
                        <span class="block text-white/90">{{ __('site.hero.title_1') }}</span>
                        <span class="block">{{ __('site.hero.title_2') }}</span>
                        <span class="relative inline-block text-lime">{{ __('site.hero.title_3') }}
                            <svg class="absolute -bottom-2 left-0 w-full text-lime/50" viewBox="0 0 300 12" fill="none" preserveAspectRatio="none"><path d="M2 9c60-6 130-8 296-4" stroke="currentColor" stroke-width="4" stroke-linecap="round"/></svg>
                        </span>
                    </h1>
                    <p class="reveal mt-6 max-w-xl text-lg leading-relaxed text-white/70">{{ __('site.hero.sub') }}</p>
                    <div class="reveal mt-8 flex flex-col gap-3 sm:flex-row">
                        <a href="{{ route('download.android') }}" class="btn-lime text-lg"><span class="ms">android</span>{{ __('site.hero.download') }}</a>
                        @if ($webReady)
                            <a href="/app/" class="btn-ghost text-lg"><span class="ms">language</span>{{ __('site.hero.web') }}</a>
                        @endif
                    </div>
                    <ul class="reveal mt-8 flex flex-wrap gap-x-5 gap-y-2 text-sm font-semibold text-white/70">
                        @foreach (__('site.hero.chips') as $chip)
                            <li class="inline-flex items-center gap-1.5"><span class="ms text-base text-lime">check_circle</span>{{ $chip }}</li>
                        @endforeach
                    </ul>
                </div>

                {{-- Phone + floating cards built from the app's own components --}}
                <div class="relative mx-auto w-full max-w-[25rem] lg:col-span-6 lg:max-w-none">
                    <div class="relative mx-auto w-[16.5rem] sm:w-[18rem] lg:w-[19rem] translate-y-6 lg:translate-y-0">
                        @include('site.partials.phone', ['src' => 'home', 'alt' => __('site.screens.items.home'), 'loading' => 'eager', 'class' => 'animate-float-slow', 'style' => '--r:-2deg'])

                        <div class="absolute -left-14 top-16 hidden w-52 animate-float rounded-3xl bg-white p-4 text-ink shadow-2xl sm:block" style="--r:-4deg; animation-delay:-2s">
                            <p class="text-xs font-bold text-muted">{{ __('site.hero.float_today') }}</p>
                            <p class="mt-1 text-2xl font-extrabold">৳{{ site_digits('2,300') }}</p>
                            <div class="mt-2 flex gap-1">
                                <span class="h-2 flex-1 rounded-full bg-cng"></span><span class="h-2 flex-1 rounded-full bg-cng"></span>
                                <span class="h-2 flex-1 rounded-full bg-paper-2"></span><span class="h-2 flex-1 rounded-full bg-paper-2"></span>
                            </div>
                            <p class="mt-2 text-xs font-bold text-income">{{ __('site.hero.float_target') }}</p>
                        </div>

                        <div class="absolute -right-6 top-40 hidden animate-float rounded-3xl bg-lime px-4 py-3 text-ink shadow-2xl sm:block lg:-right-16" style="--r:5deg; animation-delay:-4s">
                            <p class="text-xs font-bold opacity-70">{{ __('site.hero.float_profit') }}</p>
                            <p class="text-2xl font-extrabold">+৳{{ site_digits('27,766') }}</p>
                        </div>

                        <div class="absolute -left-10 bottom-24 hidden animate-float items-center gap-3 rounded-3xl bg-white p-3 pr-4 text-ink shadow-2xl sm:flex" style="--r:3deg; animation-delay:-1s">
                            <span class="grid size-11 place-items-center rounded-2xl bg-cng/15 text-cng"><span class="ms">electric_rickshaw</span></span>
                            @include('site.partials.plate', ['top' => $bn ? 'ঢাকা মেট্রো-থ' : 'Dhaka Metro-Tha', 'num' => site_digits('14-5286')])
                        </div>

                        <div class="absolute -right-4 bottom-10 hidden animate-float items-center gap-2 rounded-2xl bg-ink-2 px-4 py-3 text-white shadow-2xl ring-1 ring-white/10 sm:flex lg:-right-12" style="animation-delay:-3s">
                            <span class="ms text-warn">savings</span>
                            <span class="text-sm font-bold">{{ __('site.hero.float_due') }} · ৳{{ site_digits('1,000') }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    {{-- ───────────────────────── Vehicle types marquee ───────────────────────── --}}
    <section class="overflow-hidden py-10" aria-label="{{ __('site.types.title') }}">
        <p class="mb-5 text-center text-sm font-bold uppercase tracking-[.2em] text-muted">{{ __('site.types.title') }}</p>
        <div class="relative [mask-image:linear-gradient(90deg,transparent,#000_10%,#000_90%,transparent)]">
            <div class="flex w-max animate-marquee gap-4">
                @foreach (range(1, 2) as $_)
                    @foreach ($types as $i => [$icon, $bg])
                        <div class="flex items-center gap-3 rounded-full border border-line bg-white py-2 pl-2 pr-6">
                            <span class="grid size-11 place-items-center rounded-2xl {{ $bg }} text-white"><span class="ms">{{ $icon }}</span></span>
                            <span class="text-lg font-bold">{{ $typeNames[$i] }}</span>
                        </div>
                    @endforeach
                @endforeach
            </div>
        </div>
    </section>

    {{-- ───────────────────────── Pain points ───────────────────────── --}}
    <section class="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8 lg:py-20">
        <div class="reveal max-w-2xl">
            <span class="kicker"><span class="ms text-base">bolt</span>{{ __('site.pain.kicker') }}</span>
            <h2 class="section-title mt-5">{{ __('site.pain.title') }}</h2>
        </div>
        <div class="mt-10 grid gap-5 md:grid-cols-3">
            @foreach (__('site.pain.items') as $i => $item)
                <article class="reveal card p-7" style="transition-delay: {{ $i * 90 }}ms">
                    <span class="grid size-14 place-items-center rounded-2xl bg-expense/10 text-expense"><span class="ms text-2xl">{{ $item['icon'] }}</span></span>
                    <h3 class="mt-6 text-xl font-extrabold">{{ $item['title'] }}</h3>
                    <p class="mt-2 leading-relaxed text-muted">{{ $item['body'] }}</p>
                </article>
            @endforeach
        </div>
    </section>

    {{-- ───────────────────────── Features (bento) ───────────────────────── --}}
    <section id="features" class="scroll-mt-24 bg-paper-2/60 py-16 lg:py-24">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="reveal mx-auto max-w-2xl text-center">
                <span class="kicker"><span class="ms text-base">apps</span>{{ __('site.features.kicker') }}</span>
                <h2 class="section-title mt-5">{{ __('site.features.title') }}</h2>
                <p class="mt-4 text-lg text-muted">{{ __('site.features.sub') }}</p>
            </div>

            <div class="mt-12 grid gap-5 lg:grid-cols-6">
                {{-- Daily collection --}}
                <article class="reveal lanes relative overflow-hidden rounded-4xl bg-ink p-6 text-white sm:p-8 lg:col-span-4">
                    <div class="grid gap-8 md:grid-cols-2 md:items-center">
                        <div>
                            <span class="grid size-12 place-items-center rounded-2xl bg-lime text-ink"><span class="ms">payments</span></span>
                            <h3 class="mt-5 text-2xl font-extrabold sm:text-3xl">{{ __('site.features.daily.title') }}</h3>
                            <p class="mt-3 leading-relaxed text-white/70">{{ __('site.features.daily.body') }}</p>
                        </div>
                        <div class="space-y-3" aria-hidden="true">
                            @foreach ([['electric_rickshaw', 'bg-cng/15 text-cng', $bn ? 'সবুজ সিএনজি' : 'Green CNG', '1,100', true], ['electric_rickshaw', 'bg-cng/15 text-cng', $bn ? 'নতুন সিএনজি' : 'New CNG', '1,000', false], ['directions_car', 'bg-car/15 text-car', $bn ? 'সাদা এক্সিও' : 'White Axio', '1,800', true]] as [$ic, $tone, $name, $amt, $full])
                                <div class="rounded-3xl bg-white p-3 text-ink">
                                    <div class="flex items-center gap-3">
                                        <span class="grid size-10 place-items-center rounded-2xl {{ $tone }}"><span class="ms">{{ $ic }}</span></span>
                                        <span class="flex-1 font-bold">{{ $name }}</span>
                                        <span class="ms {{ $full ? 'text-income' : 'text-warn' }}">check_circle</span>
                                    </div>
                                    <div class="mt-2 flex items-center gap-2">
                                        <span class="flex-1 rounded-xl bg-paper px-3 py-2 font-bold">৳ {{ site_digits($amt) }}</span>
                                        <span class="rounded-xl px-3 py-2 text-sm font-bold {{ $full ? 'bg-income text-white' : 'bg-paper-2' }}">{{ $m['full'] }}</span>
                                        <span class="rounded-xl bg-paper-2 px-3 py-2 text-sm font-bold">{{ $m['off'] }}</span>
                                    </div>
                                    @unless ($full)<p class="mt-1.5 pl-1 text-xs font-bold text-warn">{{ $m['short'] }}</p>@endunless
                                </div>
                            @endforeach
                        </div>
                    </div>
                </article>

                {{-- Driver dues heat-map --}}
                <article class="reveal card p-6 sm:p-8 lg:col-span-2" style="transition-delay:80ms">
                    <span class="grid size-12 place-items-center rounded-2xl bg-warn/15 text-warn"><span class="ms">account_balance_wallet</span></span>
                    <h3 class="mt-5 text-xl font-extrabold">{{ __('site.features.dues.title') }}</h3>
                    <p class="mt-2 text-muted">{{ __('site.features.dues.body') }}</p>
                    <div class="mt-6 grid grid-cols-9 gap-1.5" aria-hidden="true">
                        @foreach (str_split('ffpffffofffffpffffooffffffpfffffffffpffofffffffpfffffofffff') as $c)
                            <span class="aspect-square rounded-[5px] {{ ['f' => 'bg-income', 'p' => 'bg-warn', 'o' => 'bg-ink/20'][$c] }}"></span>
                        @endforeach
                    </div>
                    <div class="mt-3 flex gap-4 text-xs font-semibold text-muted">
                        @foreach ([['bg-income', 0], ['bg-warn', 1], ['bg-ink/20', 2]] as [$bg, $k])
                            <span class="inline-flex items-center gap-1.5"><span class="size-2.5 rounded-sm {{ $bg }}"></span>{{ $m['legend'][$k] }}</span>
                        @endforeach
                    </div>
                </article>

                {{-- Profit leaderboard --}}
                <article class="reveal card p-6 sm:p-8 lg:col-span-3">
                    <div class="flex items-start justify-between gap-4">
                        <div>
                            <span class="grid size-12 place-items-center rounded-2xl bg-income/15 text-income"><span class="ms">emoji_events</span></span>
                            <h3 class="mt-5 text-xl font-extrabold">{{ __('site.features.profit.title') }}</h3>
                        </div>
                    </div>
                    <p class="mt-2 text-muted">{{ __('site.features.profit.body') }}</p>
                    <div class="mt-6 space-y-4" aria-hidden="true">
                        @foreach ([['local_shipping', 'bg-pickup', 'bg-pickup/15 text-pickup', $bn ? 'টাটা পিকআপ' : 'Tata Pickup', '14,260', 100], ['electric_rickshaw', 'bg-cng', 'bg-cng/15 text-cng', $bn ? 'নতুন সিএনজি' : 'New CNG', '5,800', 42], ['directions_car', 'bg-car', 'bg-car/15 text-car', $bn ? 'সাদা এক্সিও' : 'White Axio', '3,324', 24]] as $i => [$ic, $bg, $tone, $name, $amt, $w])
                            <div class="flex items-center gap-3">
                                <span class="w-5 text-lg font-extrabold {{ $i === 0 ? 'text-warn' : 'text-muted' }}">{{ site_digits($i + 1) }}</span>
                                <span class="grid size-10 shrink-0 place-items-center rounded-2xl {{ $tone }}"><span class="ms">{{ $ic }}</span></span>
                                <div class="min-w-0 flex-1">
                                    <div class="flex justify-between gap-2 font-bold"><span class="truncate">{{ $name }}</span><span>৳{{ site_digits($amt) }}</span></div>
                                    <div class="mt-1.5 h-2 rounded-full bg-paper-2"><div class="h-2 rounded-full {{ $bg }}" style="width: {{ $w }}%"></div></div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </article>

                {{-- Fuel numpad --}}
                <article class="reveal relative overflow-hidden rounded-4xl bg-lime p-6 text-ink sm:p-8 lg:col-span-3" style="transition-delay:80ms">
                    <div class="grid gap-6 sm:grid-cols-2 sm:items-center">
                        <div>
                            <span class="grid size-12 place-items-center rounded-2xl bg-ink text-lime"><span class="ms">local_gas_station</span></span>
                            <h3 class="mt-5 text-xl font-extrabold">{{ __('site.features.fuel.title') }}</h3>
                            <p class="mt-2 text-ink/70">{{ __('site.features.fuel.body') }}</p>
                        </div>
                        <div class="rounded-3xl bg-white/70 p-4 backdrop-blur" aria-hidden="true">
                            <p class="text-center text-3xl font-extrabold">৳{{ site_digits('2,450') }}</p>
                            <div class="mt-3 grid grid-cols-3 gap-1.5">
                                @foreach (['1','2','3','4','5','6','7','8','9','00','0','⌫'] as $k)
                                    <span class="grid h-9 place-items-center rounded-xl bg-paper-2/80 font-bold">{{ $k === '⌫' ? '⌫' : site_digits($k) }}</span>
                                @endforeach
                            </div>
                            <span class="mt-2 grid h-10 place-items-center rounded-xl bg-ink font-bold text-lime">{{ $m['save'] }}</span>
                        </div>
                    </div>
                </article>

                {{-- Small feature cards --}}
                @foreach ([['trips', 'route', 'bg-car/15 text-car'], ['parts', 'build_circle', 'bg-micro/15 text-micro'], ['papers', 'event_note', 'bg-expense/10 text-expense']] as $i => [$key, $icon, $tone])
                    <article class="reveal card p-6 sm:p-7 lg:col-span-2" style="transition-delay: {{ $i * 80 }}ms">
                        <span class="grid size-12 place-items-center rounded-2xl {{ $tone }}"><span class="ms">{{ $icon }}</span></span>
                        <h3 class="mt-5 text-xl font-extrabold">{{ __("site.features.$key.title") }}</h3>
                        <p class="mt-2 text-muted">{{ __("site.features.$key.body") }}</p>
                        @if ($key === 'papers')
                            <div class="mt-5 flex items-center gap-3 rounded-2xl bg-paper p-3" aria-hidden="true">
                                <span class="grid w-12 place-items-center rounded-xl bg-warn/15 py-1 text-warn"><b class="text-lg leading-none">{{ site_digits(19) }}</b><small class="text-[10px] font-bold">{{ $bn ? 'অক্টো' : 'Oct' }}</small></span>
                                <span class="flex-1 text-sm font-bold">{{ $bn ? 'ট্যাক্স টোকেন' : 'Tax token' }}</span>
                                <span class="rounded-full bg-warn/15 px-2.5 py-1 text-xs font-bold text-warn">{{ $m['expiring'] }}</span>
                            </div>
                        @elseif ($key === 'parts')
                            <div class="mt-5 rounded-2xl bg-paper p-3" aria-hidden="true">
                                <div class="flex justify-between text-sm font-bold"><span>{{ $bn ? 'ইঞ্জিন অয়েল' : 'Engine oil' }}</span><span class="text-micro">{{ site_digits(78) }}%</span></div>
                                <div class="mt-2 h-2 rounded-full bg-paper-2"><div class="h-2 w-[78%] rounded-full bg-micro"></div></div>
                            </div>
                        @else
                            <div class="mt-5 flex items-center gap-2 rounded-2xl bg-paper p-3 text-sm font-bold" aria-hidden="true">
                                <span class="ms text-car">groups</span><span class="flex-1">{{ $bn ? 'বিয়ের রিজার্ভ' : 'Wedding hire' }}</span><span class="text-income">+৳{{ site_digits('4,500') }}</span>
                            </div>
                        @endif
                    </article>
                @endforeach

                {{-- Reports --}}
                <article class="reveal card p-6 sm:p-8 lg:col-span-3">
                    <span class="grid size-12 place-items-center rounded-2xl bg-car/15 text-car"><span class="ms">insights</span></span>
                    <h3 class="mt-5 text-xl font-extrabold">{{ __('site.features.reports.title') }}</h3>
                    <p class="mt-2 text-muted">{{ __('site.features.reports.body') }}</p>
                    <div class="mt-6 flex h-32 items-end gap-3" aria-hidden="true">
                        @foreach ([[48, 18], [72, 30], [86, 22], [64, 36], [92, 28], [58, 20]] as [$in, $out])
                            <div class="flex flex-1 items-end justify-center gap-1">
                                <span class="w-1/2 max-w-4 rounded-t-md bg-income" style="height: {{ $in }}%"></span>
                                <span class="w-1/2 max-w-4 rounded-t-md bg-expense/80" style="height: {{ $out }}%"></span>
                            </div>
                        @endforeach
                    </div>
                </article>

                {{-- Backup --}}
                <article class="reveal lanes relative overflow-hidden rounded-4xl bg-ink p-6 text-white sm:p-8 lg:col-span-3" style="transition-delay:80ms">
                    <div class="pointer-events-none absolute -right-16 -top-16 size-56 rounded-full bg-lime/15 blur-2xl"></div>
                    <span class="relative grid size-12 place-items-center rounded-2xl bg-lime text-ink"><span class="ms">cloud_done</span></span>
                    <h3 class="relative mt-5 text-xl font-extrabold">{{ __('site.features.backup.title') }}</h3>
                    <p class="relative mt-2 text-white/70">{{ __('site.features.backup.body') }}</p>
                    <div class="relative mt-6 flex items-center gap-3 rounded-2xl bg-white/10 p-3" aria-hidden="true">
                        <span class="ms text-lime">sync</span>
                        <span class="flex-1 text-sm font-semibold">{{ $bn ? 'শেষ ব্যাকআপ: আজ · ১০:৩০' : 'Last backup: today · 10:30' }}</span>
                        <span class="ms text-income">check_circle</span>
                    </div>
                </article>
            </div>
        </div>
    </section>

    {{-- ───────────────────────── How it works ───────────────────────── --}}
    <section id="how" class="scroll-mt-24 mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8 lg:py-24">
        <div class="reveal mx-auto max-w-2xl text-center">
            <span class="kicker"><span class="ms text-base">schedule</span>{{ __('site.how.kicker') }}</span>
            <h2 class="section-title mt-5">{{ __('site.how.title') }}</h2>
        </div>
        <ol class="relative mt-14 grid gap-6 md:grid-cols-3">
            <div class="pointer-events-none absolute left-[16%] right-[16%] top-10 hidden border-t-2 border-dashed border-ink/15 md:block"></div>
            @foreach (__('site.how.steps') as $i => $step)
                <li class="reveal relative text-center" style="transition-delay: {{ $i * 120 }}ms">
                    <span class="relative mx-auto grid size-20 place-items-center rounded-[1.6rem] bg-ink text-lime shadow-xl">
                        <span class="ms text-3xl">{{ $step['icon'] }}</span>
                        <span class="absolute -right-2 -top-2 grid size-8 place-items-center rounded-full bg-lime text-sm font-extrabold text-ink ring-4 ring-paper">{{ site_digits($i + 1) }}</span>
                    </span>
                    <h3 class="mt-6 text-xl font-extrabold">{{ $step['title'] }}</h3>
                    <p class="mx-auto mt-2 max-w-xs text-muted">{{ $step['body'] }}</p>
                </li>
            @endforeach
        </ol>
    </section>

    {{-- ───────────────────────── Screenshots ───────────────────────── --}}
    <section id="screens" class="scroll-mt-24 overflow-hidden bg-ink py-16 text-white lg:py-24">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="flex flex-col items-start justify-between gap-6 md:flex-row md:items-end">
                <div class="reveal max-w-2xl">
                    <span class="kicker"><span class="ms text-base">smartphone</span>{{ __('site.screens.kicker') }}</span>
                    <h2 class="section-title mt-5">{{ __('site.screens.title') }}</h2>
                    <p class="mt-4 text-lg text-white/60">{{ __('site.screens.sub') }}</p>
                </div>
                <div class="flex gap-2">
                    <button type="button" data-rail-prev="shots" class="grid size-12 place-items-center rounded-2xl bg-white/10 transition hover:bg-white/20" aria-label="Previous"><span class="ms">arrow_back</span></button>
                    <button type="button" data-rail-next="shots" class="grid size-12 place-items-center rounded-2xl bg-lime text-ink transition hover:bg-lime-2" aria-label="Next"><span class="ms">arrow_forward</span></button>
                </div>
            </div>
        </div>
        <div data-rail="shots" class="no-scrollbar mt-10 flex snap-x snap-mandatory gap-6 overflow-x-auto scroll-smooth px-4 pb-6 sm:px-6 lg:px-[max(2rem,calc((100vw-80rem)/2+2rem))]">
            @foreach (__('site.screens.items') as $src => $label)
                <figure class="w-[15rem] shrink-0 snap-center sm:w-[16.5rem]">
                    @include('site.partials.phone', ['src' => $src, 'alt' => $label, 'class' => '!border-[8px] !border-ink-3'])
                    <figcaption class="mt-4 text-center font-bold text-white/80">{{ $label }}</figcaption>
                </figure>
            @endforeach
        </div>
    </section>

    {{-- ───────────────────────── Platforms ───────────────────────── --}}
    <section class="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8 lg:py-24">
        <div class="grid items-center gap-12 lg:grid-cols-12">
            <div class="reveal lg:col-span-5">
                <span class="kicker"><span class="ms text-base">devices</span>{{ __('site.platforms.kicker') }}</span>
                <h2 class="section-title mt-5">{{ __('site.platforms.title') }}</h2>
                <p class="mt-4 text-lg text-muted">{{ __('site.platforms.body') }}</p>
                <ul class="mt-8 space-y-3">
                    @foreach (__('site.platforms.items') as [$icon, $label])
                        <li class="flex items-center gap-4 rounded-3xl border border-line bg-white p-4 font-bold">
                            <span class="grid size-11 place-items-center rounded-2xl bg-ink text-lime"><span class="ms">{{ $icon }}</span></span>{{ $label }}
                        </li>
                    @endforeach
                </ul>
            </div>
            <div class="reveal relative lg:col-span-7">
                <div class="rounded-[1.4rem] bg-ink p-2.5 shadow-[0_40px_80px_-30px_rgba(18,20,24,.5)] sm:rounded-[1.8rem] sm:p-3">
                    <div class="mb-2 flex gap-1.5 px-2 pt-1"><span class="size-2.5 rounded-full bg-expense"></span><span class="size-2.5 rounded-full bg-warn"></span><span class="size-2.5 rounded-full bg-cng"></span></div>
                    <img src="{{ asset('site/desktop.webp') }}" alt="{{ __('site.platforms.items.1.1') }}" class="w-full rounded-xl sm:rounded-2xl" width="1440" height="900" loading="lazy">
                </div>
                <div class="absolute -bottom-10 -right-2 w-28 sm:-right-6 sm:w-36 lg:w-40">
                    @include('site.partials.phone', ['src' => 'home-dark', 'alt' => '', 'class' => '!rounded-[1.6rem] !border-[6px] before:!top-1 before:!h-3 before:!w-12', 'inner' => 'rounded-[1.2rem]', 'bar' => 'h-5 px-3 text-[7px]'])
                </div>
            </div>
        </div>
    </section>

    {{-- ───────────────────────── Trust ───────────────────────── --}}
    <section class="px-3 sm:px-4">
        <div class="lanes mx-auto max-w-[88rem] rounded-[2rem] bg-ink px-5 py-16 text-white sm:rounded-5xl sm:px-8 lg:py-20">
            <div class="mx-auto max-w-7xl">
                <div class="reveal max-w-2xl">
                    <span class="kicker"><span class="ms text-base">verified</span>{{ __('site.trust.kicker') }}</span>
                    <h2 class="section-title mt-5">{{ __('site.trust.title') }}</h2>
                </div>
                <div class="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                    @foreach (__('site.trust.items') as $i => $item)
                        <article class="reveal rounded-4xl border border-white/10 bg-white/5 p-6 backdrop-blur" style="transition-delay: {{ $i * 80 }}ms">
                            <span class="grid size-12 place-items-center rounded-2xl bg-lime text-ink"><span class="ms">{{ $item['icon'] }}</span></span>
                            <h3 class="mt-5 text-lg font-extrabold">{{ $item['title'] }}</h3>
                            <p class="mt-2 text-white/60">{{ $item['body'] }}</p>
                        </article>
                    @endforeach
                </div>
            </div>
        </div>
    </section>

    {{-- ───────────────────────── FAQ ───────────────────────── --}}
    <section id="faq" class="scroll-mt-24 mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8 lg:py-24">
        <div class="grid gap-10 lg:grid-cols-12">
            <div class="reveal lg:col-span-4">
                <span class="kicker"><span class="ms text-base">support_agent</span>{{ __('site.faq.kicker') }}</span>
                <h2 class="section-title mt-5">{{ __('site.faq.title') }}</h2>
                @isset($support['phone'])
                    <a href="tel:{{ $support['phone'] }}" class="btn-outline mt-8"><span class="ms">call</span>{{ site_digits($support['phone']) }}</a>
                @endisset
            </div>
            <div class="space-y-3 lg:col-span-8">
                @foreach (__('site.faq.items') as $i => $item)
                    <details class="reveal group card overflow-hidden px-6 py-1 open:shadow-sm" @if ($i === 0) open @endif>
                        <summary class="flex cursor-pointer list-none items-center justify-between gap-4 py-5 text-lg font-bold [&::-webkit-details-marker]:hidden">
                            {{ $item['q'] }}
                            <span class="grid size-9 shrink-0 place-items-center rounded-full bg-paper-2 transition group-open:rotate-45 group-open:bg-lime"><span class="ms text-xl">add</span></span>
                        </summary>
                        <p class="pb-6 leading-relaxed text-muted">{{ $item['a'] }}</p>
                    </details>
                @endforeach
            </div>
        </div>
    </section>

    {{-- ───────────────────────── CTA ───────────────────────── --}}
    <section class="px-3 pb-16 sm:px-4 lg:pb-24">
        <div class="relative mx-auto max-w-[88rem] overflow-hidden rounded-[2rem] bg-lime px-6 py-14 text-ink sm:rounded-5xl sm:px-12 lg:py-20">
            <div class="pointer-events-none absolute -right-10 top-1/2 hidden -translate-y-1/2 gap-3 lg:flex">
                @foreach ([['electric_rickshaw', 'bg-cng', '-8deg'], ['directions_car', 'bg-car', '4deg'], ['local_shipping', 'bg-pickup', '-3deg']] as [$icon, $bg, $r])
                    <span class="grid size-28 animate-float place-items-center rounded-[2rem] {{ $bg }} text-white shadow-xl" style="--r: {{ $r }}; animation-delay: -{{ $loop->index * 2 }}s"><span class="ms text-6xl">{{ $icon }}</span></span>
                @endforeach
            </div>
            <div class="relative max-w-2xl">
                <h2 class="section-title">{{ __('site.cta.title') }}</h2>
                <p class="mt-4 text-lg text-ink/70">{{ __('site.cta.sub') }}</p>
                <div class="mt-8 flex flex-col gap-3 sm:flex-row">
                    <a href="{{ route('download.android') }}" class="btn-ink text-lg"><span class="ms text-lime">download</span>{{ __('site.hero.download') }}</a>
                    @if ($webReady)
                        <a href="/app/" class="btn border border-ink/20 text-lg hover:bg-ink/5"><span class="ms">language</span>{{ __('site.hero.web') }}</a>
                    @endif
                </div>
            </div>
        </div>
    </section>
</main>

@include('site.partials.footer')
@endsection
