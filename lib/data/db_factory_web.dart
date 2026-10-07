import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// On the web SQLite runs as WebAssembly and persists to IndexedDB.
DatabaseFactory platformDatabaseFactory() => databaseFactoryFfiWeb;

Future<String> databasePath(DatabaseFactory factory, String name) async => name;
