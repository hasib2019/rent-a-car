import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../core/env.dart';

/// Backs the SQLite file up to the hidden, app-private `appDataFolder` of the
/// owner's own Google Drive. Nothing is visible to other apps, and nothing
/// leaves the owner's account.
///
/// OAuth client ids come from `.env` (GOOGLE_CLIENT_ID, GOOGLE_SERVER_CLIENT_ID).
/// See README.md → "Google Drive setup".
class DriveBackup {
  DriveBackup._();
  static final instance = DriveBackup._();

  static const _clientId = Env.googleClientId;
  static const _serverClientId = Env.googleServerClientId;
  static const _scopes = [drive.DriveApi.driveAppdataScope];
  static const _prefix = 'garikhata-backup-';
  static const keepLatest = 10;

  bool _initialized = false;
  GoogleSignInAccount? _user;
  String? _token;

  /// Drive works on Android, iOS, macOS and web (Windows/Linux have no
  /// google_sign_in implementation — use local file export there).
  bool get platformSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Web and iOS/macOS need a client id; Android needs the web client id as
  /// `serverClientId` unless google-services.json is present.
  bool get configured {
    if (!platformSupported) return false;
    if (kIsWeb) return _clientId.isNotEmpty;
    return true;
  }

  Future<void> _init() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _clientId.isEmpty || defaultTargetPlatform == TargetPlatform.android ? null : _clientId,
      serverClientId: _serverClientId.isEmpty || kIsWeb ? null : _serverClientId,
    );
    _initialized = true;
  }

  /// Obtains an access token. With [interactive] false it only tries silently
  /// (used by auto-backup); otherwise it may show Google's account picker.
  Future<bool> connect({bool interactive = true}) async {
    await _init();
    GoogleSignInClientAuthorization? authz;
    final signIn = GoogleSignIn.instance;
    if (signIn.supportsAuthenticate()) {
      _user ??= await signIn.attemptLightweightAuthentication();
      if (_user == null && interactive) {
        _user = await signIn.authenticate(scopeHint: _scopes);
      }
      final client = _user?.authorizationClient ?? signIn.authorizationClient;
      authz = await client.authorizationForScopes(_scopes);
      if (authz == null && interactive) authz = await client.authorizeScopes(_scopes);
    } else {
      authz = await signIn.authorizationClient.authorizationForScopes(_scopes);
      if (authz == null && interactive) {
        authz = await signIn.authorizationClient.authorizeScopes(_scopes);
      }
    }
    _token = authz?.accessToken;
    return _token != null;
  }

  Future<void> disconnect() async {
    await _init();
    final token = _token;
    _token = null;
    _user = null;
    if (token != null) {
      try {
        await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: token);
      } catch (_) {}
    }
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
  }

  Future<drive.DriveApi> _api() async {
    if (_token == null && !await connect()) {
      throw StateError('Google authorization was not granted');
    }
    return drive.DriveApi(_BearerClient(_token!));
  }

  /// Runs [op], and on an expired/revoked token re-authorises once.
  Future<T> _withRetry<T>(Future<T> Function(drive.DriveApi api) op) async {
    try {
      return await op(await _api());
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status != 401) rethrow;
      final stale = _token;
      _token = null;
      if (stale != null) {
        try {
          await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: stale);
        } catch (_) {}
      }
      return op(await _api());
    }
  }

  /// The signed-in account's email (from Drive itself, works on every platform).
  Future<String?> accountEmail() => _withRetry((api) async {
        final about = await api.about.get($fields: 'user(emailAddress)');
        return about.user?.emailAddress;
      });

  Future<DateTime> upload(Uint8List bytes) => _withRetry((api) async {
        final now = DateTime.now();
        final stamp = now.toIso8601String().replaceAll(':', '-').split('.').first;
        final meta = drive.File()
          ..name = '$_prefix$stamp.db'
          ..parents = ['appDataFolder']
          ..mimeType = 'application/x-sqlite3';
        await api.files.create(
          meta,
          uploadMedia: drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/x-sqlite3'),
        );
        await _prune(api);
        return now;
      });

  Future<List<drive.File>> list() => _withRetry((api) async {
        final res = await api.files.list(
          spaces: 'appDataFolder',
          q: "name contains '$_prefix' and trashed = false",
          orderBy: 'createdTime desc',
          $fields: 'files(id,name,size,createdTime)',
          pageSize: 50,
        );
        return res.files ?? [];
      });

  Future<Uint8List> download(String fileId) => _withRetry((api) async {
        final media = await api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        final builder = BytesBuilder(copy: false);
        await for (final chunk in media.stream) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      });

  Future<void> _prune(drive.DriveApi api) async {
    final res = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains '$_prefix' and trashed = false",
      orderBy: 'createdTime desc',
      $fields: 'files(id)',
      pageSize: 100,
    );
    final files = res.files ?? [];
    for (final f in files.skip(keepLatest)) {
      try {
        await api.files.delete(f.id!);
      } catch (_) {}
    }
  }
}

class _BearerClient extends http.BaseClient {
  _BearerClient(this._token);
  final String _token;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}
