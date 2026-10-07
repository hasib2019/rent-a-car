import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'access.dart';
import 'api.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    this.businessName,
    this.district,
    this.fleetSize,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String? businessName;
  final String? district;
  final int? fleetSize;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        username: j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        businessName: j['business_name'] as String?,
        district: j['district'] as String?,
        fleetSize: (j['fleet_size'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'business_name': businessName,
        'district': district,
        'fleet_size': fleetSize,
      };
}

/// Server-controlled switches from /config.
class AppConfig {
  const AppConfig({
    this.minVersion = '0.0.0',
    this.latestVersion = '0.0.0',
    this.forceUpdate = false,
    this.updateUrl = '',
    this.maintenance = false,
    this.maintenanceMessage = '',
    this.registrationOpen = true,
    this.supportPhone = '',
    this.supportEmail = '',
    this.supportWhatsapp = '',
  });

  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrl;
  final bool maintenance;
  final String maintenanceMessage;
  final bool registrationOpen;
  final String supportPhone;
  final String supportEmail;
  final String supportWhatsapp;

  factory AppConfig.fromJson(Map<String, dynamic> j) {
    final support = (j['support'] as Map?) ?? const {};
    return AppConfig(
      minVersion: j['min_app_version'] as String? ?? '0.0.0',
      latestVersion: j['latest_app_version'] as String? ?? '0.0.0',
      forceUpdate: j['force_update'] == true,
      updateUrl: j['update_url'] as String? ?? '',
      maintenance: j['maintenance_mode'] == true,
      maintenanceMessage: j['maintenance_message'] as String? ?? '',
      registrationOpen: j['registration_open'] != false,
      supportPhone: support['phone'] as String? ?? '',
      supportEmail: support['email'] as String? ?? '',
      supportWhatsapp: support['whatsapp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'min_app_version': minVersion,
        'latest_app_version': latestVersion,
        'force_update': forceUpdate,
        'update_url': updateUrl,
        'maintenance_mode': maintenance,
        'maintenance_message': maintenanceMessage,
        'registration_open': registrationOpen,
        'support': {'phone': supportPhone, 'email': supportEmail, 'whatsapp': supportWhatsapp},
      };
}

/// Account session. The ledger itself stays offline in SQLite; the server only
/// knows who the owner is, what they may use and which screens they open.
class AuthService extends ChangeNotifier {
  AuthService._(this._p, this.appVersion, this.platform, this.deviceId, this._device);

  static Future<AuthService> load({required String Function() language}) async {
    final p = await SharedPreferences.getInstance();
    var deviceId = p.getString('device_id');
    if (deviceId == null) {
      final r = Random.secure();
      deviceId = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await p.setString('device_id', deviceId);
    }
    String version = '1.0.0';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    final platform = kIsWeb
        ? 'web'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'android',
            TargetPlatform.iOS => 'ios',
            TargetPlatform.macOS => 'macos',
            TargetPlatform.windows => 'windows',
            TargetPlatform.linux => 'linux',
            _ => 'other',
          };
    final device = await _deviceInfo(platform);
    final auth = AuthService._(p, version, platform, deviceId, device).._language = language;
    auth._restore();
    return auth;
  }

  final SharedPreferences _p;
  final String appVersion;
  final String platform;
  final String deviceId;
  final Map<String, String?> _device;
  late String Function() _language;

  late final ApiClient api = ApiClient(headers: () => {
        'Accept-Language': _language(),
        'X-Platform': platform,
        'X-App-Version': appVersion,
        'X-Device-Id': deviceId,
        if (token != null) 'Authorization': 'Bearer $token',
      });

  String? token;
  AppUser? user;
  Access access = Access.full;
  AppConfig config = const AppConfig();

  /// Set when the server signs the user out (suspended, token revoked…).
  String? signedOutReason;

  bool get loggedIn => token != null && user != null;

  bool get mustUpdate => config.forceUpdate && _compare(appVersion, config.minVersion) < 0;

  Map<String, dynamic> get _devicePayload => {
        'id': deviceId,
        'platform': platform,
        'app_version': appVersion,
        ..._device,
      };

  void _restore() {
    token = _p.getString('auth_token');
    final u = _p.getString('auth_user');
    if (u != null) user = AppUser.fromJson(jsonDecode(u) as Map<String, dynamic>);
    final a = _p.getString('auth_access');
    if (a != null) access = Access.fromJson(jsonDecode(a) as Map<String, dynamic>);
    final c = _p.getString('app_config');
    if (c != null) config = AppConfig.fromJson(jsonDecode(c) as Map<String, dynamic>);
  }

  Future<void> _persist() async {
    if (token == null) {
      await _p.remove('auth_token');
      await _p.remove('auth_user');
      await _p.remove('auth_access');
    } else {
      await _p.setString('auth_token', token!);
      if (user != null) await _p.setString('auth_user', jsonEncode(user!.toJson()));
      await _p.setString('auth_access', jsonEncode(access.toJson()));
    }
  }

  Future<void> _applySession(Map<String, dynamic> json) async {
    if (json['token'] != null) token = json['token'] as String;
    if (json['user'] != null) user = AppUser.fromJson(json['user'] as Map<String, dynamic>);
    if (json.containsKey('access')) access = Access.fromJson(json['access'] as Map<String, dynamic>?);
    signedOutReason = null;
    await _persist();
    notifyListeners();
  }

  /// Called on start: refreshes config, profile and access. Offline is fine —
  /// the cached session keeps working.
  Future<void> refresh() async {
    try {
      final c = await api.get('config');
      config = AppConfig.fromJson((c['data'] as Map<String, dynamic>?) ?? const {});
      await _p.setString('app_config', jsonEncode(config.toJson()));
      notifyListeners();
    } catch (_) {}

    if (token == null) return;
    try {
      await _applySession(await api.get('me'));
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isSuspended) await _signOutLocally(e.message);
    }
  }

  Future<void> login(String login, String password) async {
    await _applySession(await api.post('auth/login', {'login': login.trim(), 'password': password, 'device': _devicePayload}));
  }

  Future<void> register(Map<String, dynamic> fields) async {
    await _applySession(await api.post('auth/register', {...fields, 'device': _devicePayload}));
  }

  Future<String> forgotPassword(String email) async {
    final res = await api.post('auth/forgot-password', {'email': email.trim()});
    return res['message'] as String? ?? '';
  }

  Future<String> resetPassword({required String email, required String code, required String password}) async {
    final res = await api.post('auth/reset-password', {
      'email': email.trim(),
      'code': code.trim(),
      'password': password,
      'password_confirmation': password,
    });
    return res['message'] as String? ?? '';
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    await _applySession(await api.put('me', fields));
  }

  Future<void> changePassword(String current, String next) async {
    await api.put('me/password', {'current_password': current, 'password': next, 'password_confirmation': next});
  }

  Future<void> deleteAccount(String password) async {
    await api.delete('me', {'password': password});
    await _signOutLocally(null);
  }

  Future<void> logout() async {
    try {
      await api.post('auth/logout');
    } catch (_) {}
    await _signOutLocally(null);
  }

  Future<void> _signOutLocally(String? reason) async {
    token = null;
    user = null;
    access = Access.full;
    signedOutReason = reason;
    await _persist();
    notifyListeners();
  }

  static int _compare(String a, String b) {
    List<int> parts(String v) => v.split('.').map((e) => int.tryParse(e.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < 3; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d.sign;
    }
    return 0;
  }

  static Future<Map<String, String?>> _deviceInfo(String platform) async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final w = await info.webBrowserInfo;
        return {'model': w.browserName.name, 'os_version': 'Web'};
      }
      switch (platform) {
        case 'android':
          final a = await info.androidInfo;
          return {'model': '${a.manufacturer} ${a.model}', 'os_version': 'Android ${a.version.release}'};
        case 'ios':
          final i = await info.iosInfo;
          return {'model': i.modelName, 'os_version': 'iOS ${i.systemVersion}'};
        case 'macos':
          final m = await info.macOsInfo;
          return {'model': m.modelName, 'os_version': 'macOS ${m.osRelease}'};
        default:
          return {'model': platform, 'os_version': Platform.operatingSystemVersion};
      }
    } catch (_) {
      return {};
    }
  }
}
