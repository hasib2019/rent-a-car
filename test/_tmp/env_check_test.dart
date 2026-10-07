import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gari_khata/core/env.dart';

void main() {
  test('env', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // ignore: avoid_print
    print('android: ${Env.apiBaseUrl}');
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    // ignore: avoid_print
    print('macos: ${Env.apiBaseUrl} timeout=${Env.apiTimeout.inSeconds}s gcid="${Env.googleClientId}"');
    debugDefaultTargetPlatformOverride = null;
  });
}
