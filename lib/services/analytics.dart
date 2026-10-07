import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart';

/// Records which screens are opened and sends them to the backend in small
/// batches. Events wait on the device while offline or signed out, so screens
/// opened before login are sent once the owner signs in.
class Analytics with WidgetsBindingObserver {
  Analytics._();
  static final Analytics instance = Analytics._();

  static const _key = 'analytics_queue';
  static const _maxQueue = 500;

  AuthService? _auth;
  SharedPreferences? _prefs;
  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;
  bool _sending = false;
  String _session = _newSession();
  String? _last;
  DateTime _lastAt = DateTime(2000);

  static String _newSession() {
    final r = Random.secure();
    return List.generate(12, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  Future<void> init(AuthService auth) async {
    _auth = auth;
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString(_key);
    if (saved != null) {
      try {
        _queue.addAll((jsonDecode(saved) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    WidgetsBinding.instance.addObserver(this);
    auth.addListener(() {
      if (auth.loggedIn) flush();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  /// [name] must be lowercase snake_case (validated by the server).
  void screen(String name) {
    final now = DateTime.now();
    // Ignore rebuild duplicates.
    if (name == _last && now.difference(_lastAt).inMilliseconds < 1500) return;
    _last = name;
    _lastAt = now;
    _queue.add({'screen': name, 'viewed_at': now.toUtc().toIso8601String(), 'session_id': _session});
    if (_queue.length > _maxQueue) _queue.removeRange(0, _queue.length - _maxQueue);
    _save();
    if (_queue.length >= 20) flush();
  }

  Future<void> flush() async {
    final auth = _auth;
    if (_sending || auth == null || !auth.loggedIn || _queue.isEmpty) return;
    _sending = true;
    final batch = _queue.take(100).toList();
    try {
      await auth.api.post('events', {'events': batch});
      _queue.removeRange(0, batch.length);
      await _save();
    } catch (_) {
      // Keep the batch for the next try.
    } finally {
      _sending = false;
    }
  }

  Future<void> _save() async => _prefs?.setString(_key, jsonEncode(_queue));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      flush();
    } else if (state == AppLifecycleState.resumed) {
      _session = _newSession();
    }
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
