@php($bn = app()->getLocale() === 'bn')
<div class="flex items-center rounded-full p-1 text-sm font-bold {{ $dark ?? false ? 'bg-white/10' : 'bg-paper-2' }}">
    <a href="{{ route('lang', 'bn') }}" @class(['rounded-full px-3 py-1.5 transition', 'bg-ink text-paper' => $bn && ! ($dark ?? false), 'bg-lime text-ink' => $bn && ($dark ?? false), 'text-muted hover:text-ink' => ! $bn && ! ($dark ?? false), 'text-white/60 hover:text-white' => ! $bn && ($dark ?? false)])>বাং</a>
    <a href="{{ route('lang', 'en') }}" @class(['rounded-full px-3 py-1.5 transition', 'bg-ink text-paper' => ! $bn && ! ($dark ?? false), 'bg-lime text-ink' => ! $bn && ($dark ?? false), 'text-muted hover:text-ink' => $bn && ! ($dark ?? false), 'text-white/60 hover:text-white' => $bn && ($dark ?? false)])>EN</a>
</div>
