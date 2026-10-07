@php($dark = $dark ?? (str_contains($src, 'dark') || $src === 'driver'))
<figure class="phone {{ $class ?? '' }}" style="{{ $style ?? '' }}">
    <div class="overflow-hidden {{ $inner ?? 'rounded-[1.9rem]' }} {{ $dark ? 'bg-[#0b0d10] text-white' : 'bg-paper text-ink' }}">
        {{-- Status bar so the camera notch never covers the screen content --}}
        <div class="flex {{ $bar ?? 'h-8 px-6 text-[11px]' }} items-center justify-between font-bold" aria-hidden="true">
            <span>{{ site_digits('9:41') }}</span>
            <span class="flex items-center gap-1">
                <svg viewBox="0 0 18 12" class="h-2.5 w-auto" fill="currentColor"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5" width="3" height="7" rx="1"/><rect x="10" y="2.5" width="3" height="9.5" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg>
                <svg viewBox="0 0 26 12" class="h-2.5 w-auto" fill="none"><rect x="1" y="1" width="21" height="10" rx="3" stroke="currentColor" stroke-opacity=".5"/><rect x="3" y="3" width="15" height="6" rx="1.5" fill="currentColor"/><rect x="23.5" y="4" width="1.5" height="4" rx=".75" fill="currentColor" fill-opacity=".5"/></svg>
            </span>
        </div>
        <img src="{{ asset("site/$src.webp") }}" alt="{{ $alt ?? '' }}" width="390" height="844" loading="{{ $loading ?? 'lazy' }}" decoding="async">
    </div>
</figure>
