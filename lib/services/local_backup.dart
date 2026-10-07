import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Save / open the raw SQLite backup through the platform file dialog
/// (Downloads on web, Storage Access Framework on Android, Files on iOS).
class LocalBackup {
  static String fileName() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'garikhata-${n.year}${two(n.month)}${two(n.day)}-${two(n.hour)}${two(n.minute)}.db';
  }

  /// Returns false if the user cancelled.
  static Future<bool> save(Uint8List bytes) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName(),
      bytes: bytes,
      mimeType: 'application/x-sqlite3',
      dialogTitle: 'GariKhata backup',
    );
    return uri != null;
  }

  /// Returns null if the user cancelled.
  static Future<Uint8List?> open() async {
    final file = await FilePicker.pickFile(dialogTitle: 'GariKhata backup');
    if (file == null) return null;
    return file.readAsBytes();
  }
}
