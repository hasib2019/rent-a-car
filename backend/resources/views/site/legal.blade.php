@extends('site.layout')

@php($title = $page === 'privacy' ? __('site.legal.privacy_title') : __('site.legal.deletion_title'))
@section('title', $title.' · '.__('site.brand'))

@section('content')
@include('site.partials.nav')

<main class="mx-auto max-w-3xl px-4 pb-20 pt-32 sm:px-6">
    <span class="kicker"><span class="ms text-base">{{ $page === 'privacy' ? 'policy' : 'delete_forever' }}</span>{{ __('site.brand') }}</span>
    <h1 class="mt-5 text-4xl font-extrabold tracking-tight sm:text-5xl">{{ $title }}</h1>
    <p class="mt-3 text-muted">{{ __('site.legal.updated') }}: {{ site_digits(now()->format('d/m/Y')) }}</p>

    <div class="mt-10 space-y-4">
        @foreach (__('site.legal.'.$page) as $i => [$heading, $body])
            <section class="card p-6 sm:p-8">
                <h2 class="flex items-center gap-3 text-xl font-extrabold">
                    <span class="grid size-9 place-items-center rounded-xl bg-lime text-sm font-extrabold">{{ site_digits($i + 1) }}</span>{{ $heading }}
                </h2>
                <p class="mt-3 leading-relaxed text-muted">{{ $body }}</p>
            </section>
        @endforeach
    </div>

    @if ($support)
        <div class="lanes mt-8 rounded-4xl bg-ink p-6 text-white sm:p-8">
            <h2 class="text-xl font-extrabold">{{ __('site.footer.contact') }}</h2>
            <div class="mt-4 flex flex-wrap gap-3">
                @isset($support['phone'])<a href="tel:{{ $support['phone'] }}" class="btn-lime !py-3"><span class="ms">call</span>{{ site_digits($support['phone']) }}</a>@endisset
                @isset($support['email'])<a href="mailto:{{ $support['email'] }}" class="btn-ghost !py-3"><span class="ms">mail</span>{{ $support['email'] }}</a>@endisset
            </div>
        </div>
    @endif
</main>

@include('site.partials.footer')
@endsection
