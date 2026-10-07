import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Android, iOS and macOS use the native sqflite plugin; Windows and Linux use
/// the FFI implementation backed by a bundled SQLite.
DatabaseFactory platformDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return mobile.databaseFactory;
}

Future<String> databasePath(DatabaseFactory factory, String name) async =>
    p.join(await factory.getDatabasesPath(), name);
