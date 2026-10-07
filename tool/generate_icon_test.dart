// Renders the GariKhata app icon from code.
// Run: flutter test tool/generate_icon_test.dart && dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' hide TextStyle;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _ink = Color(0xFF121418);
const _lime = Color(0xFFD4FF3A);

Future<void> _render(String path, {required bool background, double scale = 1}) async {
  const size = 1024.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec, const Rect.fromLTWH(0, 0, size, size));

  if (background) {
    c.drawRect(const Rect.fromLTWH(0, 0, size, size), Paint()..color = _ink);
    // Faint lane markings.
    final lane = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    c.save();
    c.translate(size * 0.78, -40);
    c.rotate(0.42);
    for (var l = 0; l < 3; l++) {
      for (var y = 0.0; y < size * 1.6; y += 120) {
        c.drawLine(Offset(l * 110.0, y), Offset(l * 110.0, y + 56), lane);
      }
    }
    c.restore();
  }

  c.save();
  c.translate(size / 2, size / 2);
  c.scale(scale);
  c.rotate(-0.10);
  // Number-plate shaped lime card.
  const plate = Rect.fromLTWH(-330, -300, 660, 600);
  c.drawRRect(RRect.fromRectAndRadius(plate.shift(const Offset(0, 22)), const Radius.circular(150)), Paint()..color = const Color(0x55000000));
  c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(150)), Paint()..color = _lime);
  // Colour band like the in-app plates.
  c.save();
  c.clipRRect(RRect.fromRectAndRadius(plate, const Radius.circular(150)));
  c.drawRect(const Rect.fromLTWH(-330, -300, 70, 600), Paint()..color = const Color(0xFF22C17A));
  c.restore();

  final pb = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center, fontFamily: 'AnekBangla', fontSize: 520, fontWeight: FontWeight.w800, height: 1))
    ..pushStyle(ui.TextStyle(color: _ink, fontFamily: 'AnekBangla', fontSize: 520, fontWeight: FontWeight.w800))
    ..addText('৳');
  final para = pb.build()..layout(const ui.ParagraphConstraints(width: 600));
  c.drawParagraph(para, Offset(-300 + 35, -para.height / 2 + 10));

  // Little "road" dashes under the sign.
  final dash = Paint()..color = _ink;
  for (var i = 0; i < 3; i++) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-110 + i * 90.0, 190, 56, 22), const Radius.circular(11)), dash);
  }
  c.restore();

  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate icon', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('AnekBangla')
        ..addFont(Future.value(ByteData.view(Uint8List.fromList(File('assets/fonts/AnekBangla-ExtraBold.ttf').readAsBytesSync()).buffer)));
      await loader.load();
      await _render('assets/icon/icon.png', background: true);
      await _render('assets/icon/icon_foreground.png', background: false, scale: 0.62);
    });
    expect(File('assets/icon/icon.png').existsSync(), isTrue);
    expect(math.pi > 3, isTrue);
  });
}
