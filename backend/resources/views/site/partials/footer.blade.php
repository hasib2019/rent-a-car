<footer class="lanes bg-ink text-white">
    <div class="mx-auto max-w-7xl px-4 pb-10 pt-16 sm:px-6 lg:px-8">
        <div class="grid gap-12 md:grid-cols-12">
            <div class="md:col-span-5">
                @include('site.partials.logo', ['dark' => true])
                <p class="mt-4 max-w-sm text-white/60">{{ __('site.footer.tagline') }}</p>
                <div class="mt-6 flex flex-wrap gap-3">
                    <a href="{{ route('download.android') }}" class="btn-lime !px-5 !py-3 text-sm"><span class="ms">android</span>{{ __('site.hero.download') }}</a>
                    @if ($webReady)
                        <a href="/app/" class="btn-ghost !px-5 !py-3 text-sm"><span class="ms">language</span>{{ __('site.hero.web') }}</a>
                    @endif
                </div>
            </div>
            <div class="grid grid-cols-2 gap-8 md:col-span-7 md:grid-cols-3">
                <div>
                    <h3 class="text-sm font-bold uppercase tracking-wider text-lime">{{ __('site.footer.product') }}</h3>
                    <ul class="mt-4 space-y-2.5 text-white/70">
                        @foreach (['features', 'how', 'screens', 'faq'] as $id)
                            <li><a class="hover:text-white" href="{{ route('home') }}#{{ $id }}">{{ __("site.nav.$id") }}</a></li>
                        @endforeach
                    </ul>
                </div>
                <div>
                    <h3 class="text-sm font-bold uppercase tracking-wider text-lime">{{ __('site.footer.company') }}</h3>
                    <ul class="mt-4 space-y-2.5 text-white/70">
                        <li><a class="hover:text-white" href="{{ route('privacy') }}">{{ __('site.footer.privacy') }}</a></li>
                        <li><a class="hover:text-white" href="{{ route('deletion') }}">{{ __('site.footer.deletion') }}</a></li>
                        <li><a class="hover:text-white" href="{{ route('login') }}">{{ __('site.footer.admin') }}</a></li>
                    </ul>
                </div>
                @if ($support)
                    <div class="col-span-2 md:col-span-1">
                        <h3 class="text-sm font-bold uppercase tracking-wider text-lime">{{ __('site.footer.contact') }}</h3>
                        <ul class="mt-4 space-y-2.5 text-white/70">
                            @isset($support['phone'])<li><a class="inline-flex items-center gap-2 hover:text-white" href="tel:{{ $support['phone'] }}"><span class="ms text-base">call</span>{{ site_digits($support['phone']) }}</a></li>@endisset
                            @isset($support['whatsapp'])<li><a class="inline-flex items-center gap-2 hover:text-white" href="https://wa.me/88{{ ltrim(preg_replace('/\D/', '', $support['whatsapp']), '88') }}"><span class="ms text-base">chat</span>WhatsApp</a></li>@endisset
                            @isset($support['email'])<li><a class="inline-flex items-center gap-2 break-all hover:text-white" href="mailto:{{ $support['email'] }}"><span class="ms text-base">mail</span>{{ $support['email'] }}</a></li>@endisset
                        </ul>
                    </div>
                @endif
            </div>
        </div>
        <div class="mt-14 flex flex-col items-center justify-between gap-4 border-t border-white/10 pt-6 text-sm text-white/50 sm:flex-row">
            <p>© {{ site_digits(date('Y')) }} {{ __('site.brand') }}. {{ __('site.footer.rights') }}</p>
            <p class="inline-flex items-center gap-1.5">{{ __('site.footer.made') }} <span class="inline-block size-2.5 rounded-full bg-[#006a4e] ring-2 ring-[#f42a41]/80"></span></p>
        </div>
    </div>
</footer>
