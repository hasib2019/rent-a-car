<?php

namespace App\Http\Controllers\Site;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class SiteController extends Controller
{
    public const APK = 'downloads/garikhata.apk';

    public function home(): View
    {
        return view('site.home', $this->shared());
    }

    public function privacy(): View
    {
        return view('site.legal', [...$this->shared(), 'page' => 'privacy']);
    }

    public function deletion(): View
    {
        return view('site.legal', [...$this->shared(), 'page' => 'deletion']);
    }

    public function download(): BinaryFileResponse|RedirectResponse
    {
        $path = public_path(self::APK);
        if (! is_file($path)) {
            return redirect()->route('home')->with('notice', __('site.download_missing'));
        }

        return response()->download($path, 'GariKhata.apk', ['Content-Type' => 'application/vnd.android.package-archive']);
    }

    public function locale(Request $request, string $locale): RedirectResponse
    {
        $request->session()->put('site_locale', $locale === 'en' ? 'en' : 'bn');

        return redirect()->to(url()->previous() ?: route('home'));
    }

    /** Data every site page uses. */
    private function shared(): array
    {
        $s = AppSetting::values();

        return [
            'support' => array_filter([
                'phone' => $s['support_phone'] ?? '',
                'whatsapp' => $s['support_whatsapp'] ?? '',
                'email' => $s['support_email'] ?? '',
            ]),
            'apkReady' => is_file(public_path(self::APK)),
            'webReady' => is_file(public_path('app/index.html')),
        ];
    }
}
