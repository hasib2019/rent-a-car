<x-mail::message>
# পাসওয়ার্ড রিসেট / Password reset

হ্যালো {{ $name }},

আপনার গাড়ির খাতা অ্যাকাউন্টের পাসওয়ার্ড রিসেট কোড:
Your GariKhata password reset code is:

<x-mail::panel>
<span style="font-size: 28px; letter-spacing: 8px; font-weight: 700;">{{ $code }}</span>
</x-mail::panel>

কোডটি ১৫ মিনিট কাজ করবে। আপনি অনুরোধ না করে থাকলে এই ইমেইল উপেক্ষা করুন।
The code works for 15 minutes. If you didn't ask for it, ignore this email.

{{ config('app.name') }}
</x-mail::message>
