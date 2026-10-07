import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences persisted with shared_preferences.
class Settings extends ChangeNotifier {
  Settings._(this._p);

  static Future<Settings> load() async => Settings._(await SharedPreferences.getInstance());

  final SharedPreferences _p;

  bool get onboarded => _p.getBool('onboarded') ?? false;
  bool get isBangla => (_p.getString('lang') ?? 'bn') == 'bn';
  bool get _bnDigits => _p.getBool('bn_digits') ?? true;
  bool get banglaDigitsPref => _bnDigits;
  bool get useBanglaDigits => isBangla && _bnDigits;
  String get ownerName => _p.getString('owner_name') ?? '';
  String get businessName => _p.getString('business_name') ?? '';
  bool get autoBackup => _p.getBool('auto_backup') ?? false;
  String? get driveEmail => _p.getString('drive_email');
  DateTime? get lastBackup {
    final s = _p.getString('last_backup');
    return s == null ? null : DateTime.tryParse(s);
  }

  ThemeMode get themeMode => switch (_p.getString('theme')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> _set(Future<bool> f) async {
    await f;
    notifyListeners();
  }

  Future<void> setOnboarded() => _set(_p.setBool('onboarded', true));
  Future<void> setBangla(bool v) => _set(_p.setString('lang', v ? 'bn' : 'en'));
  Future<void> setBanglaDigits(bool v) => _set(_p.setBool('bn_digits', v));
  Future<void> setOwnerName(String v) => _set(_p.setString('owner_name', v.trim()));
  Future<void> setBusinessName(String v) => _set(_p.setString('business_name', v.trim()));
  Future<void> setAutoBackup(bool v) => _set(_p.setBool('auto_backup', v));
  Future<void> setLastBackup(DateTime v) => _set(_p.setString('last_backup', v.toIso8601String()));
  Future<void> setDriveEmail(String? v) => _set(v == null ? _p.remove('drive_email') : _p.setString('drive_email', v));
  Future<void> setThemeMode(ThemeMode m) => _set(_p.setString('theme', switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      }));
}
