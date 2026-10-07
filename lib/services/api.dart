import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/env.dart';

/// A failed API call, with Laravel's field errors when there are any.
class ApiException implements Exception {
  ApiException(this.status, this.message, {this.code, this.fieldErrors = const {}});

  /// 0 means the server could not be reached.
  final int status;
  final String message;
  final String? code;
  final Map<String, String> fieldErrors;

  bool get isOffline => status == 0;
  bool get isUnauthorized => status == 401;
  bool get isSuspended => code == 'account_suspended';
  bool get isMaintenance => code == 'maintenance';

  String? field(String name) => fieldErrors[name];

  @override
  String toString() => message;
}

/// Thin JSON client for /api/v1. Every request carries the platform, app
/// version and device id so the admin panel can show them.
class ApiClient {
  ApiClient({required this.headers});

  /// Supplies auth / locale / device headers at call time.
  final Map<String, String> Function() headers;
  final http.Client _http = http.Client();

  Uri _uri(String path) => Uri.parse('${Env.apiBaseUrl}/api/v1/$path');

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);
  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) => _send('POST', path, body);
  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) => _send('PUT', path, body);
  Future<Map<String, dynamic>> delete(String path, [Map<String, dynamic>? body]) => _send('DELETE', path, body);

  Future<Map<String, dynamic>> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final request = http.Request(method, _uri(path))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...headers(),
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(request).timeout(Env.apiTimeout));
    } on TimeoutException {
      throw ApiException(0, 'timeout');
    } catch (_) {
      throw ApiException(0, 'offline');
    }

    Map<String, dynamic> json = const {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {}
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    final errors = <String, String>{};
    final raw = json['errors'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List && v.isNotEmpty) errors[k.toString()] = v.first.toString();
      });
    }
    throw ApiException(
      res.statusCode,
      (json['message'] as String?) ?? 'HTTP ${res.statusCode}',
      code: json['code'] as String?,
      fieldErrors: errors,
    );
  }
}
