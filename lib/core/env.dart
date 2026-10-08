import 'package:flutter/foundation.dart';

/// Every build-time setting of the app, read from the `.env` file in the
/// project root. Flutter loads that file itself — no package needed:
///   flutter run --dart-define-from-file=.env
/// (VS Code's launch configs already pass it.) Copy `.env.example` to `.env`
/// to start. A single key can still be overridden on the command line with
/// `--dart-define=KEY=value`, which wins over the file.
///
/// Values are compiled into the app, so never put a server secret here.
abstract final class Env {
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Seconds before an API call gives up and is treated as offline.
  static const apiTimeout = Duration(seconds: int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 20));

  /// Google OAuth client ids for Drive backup (see README → Google Drive setup).
  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Where the GariKhata backend lives, without a trailing slash.
  ///
  /// * empty: the local dev server, `https://garikhata.etalikhata.com`
  /// * `origin`: a web build talks to the server it is served from (the
  ///   backend hosts the web app under /app/)
  /// * anything else is used as is
  ///
  /// On Android, `localhost` / `127.0.0.1` become `10.0.2.2`, the emulator's
  /// address for the computer it runs on, so one value works for web,
  /// desktop and the emulator. A real phone needs the computer's LAN IP.
  static String get apiBaseUrl {
    if (_apiBaseUrl == 'origin' && kIsWeb) return Uri.base.origin;
    final raw = _apiBaseUrl.isEmpty || _apiBaseUrl == 'origin' ? 'https://garikhata.etalikhata.com' : _apiBaseUrl;
    var uri = Uri.parse(raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      uri = uri.replace(host: '10.0.2.2');
    }
    return uri.toString();
  }
}
