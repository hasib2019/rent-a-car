<a href="{{ route('home') }}" class="group flex items-center gap-2.5" aria-label="{{ __('site.brand') }}">
    <img src="{{ asset('site/icon.webp') }}" alt="" class="size-10 rounded-xl shadow-sm transition group-hover:rotate-[-6deg]" width="40" height="40">
    <span class="text-lg font-extrabold tracking-tight {{ $dark ?? false ? 'text-white' : 'text-ink' }}">{{ __('site.brand') }}</span>
</a>
