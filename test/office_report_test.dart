import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gari_khata/core/catalog.dart';
import 'package:gari_khata/core/theme.dart';
import 'package:gari_khata/data/models.dart';
import 'package:gari_khata/data/repository.dart';
import 'package:gari_khata/services/auth.dart';
import 'package:gari_khata/services/settings.dart';
import 'package:gari_khata/state/app_state.dart';
import 'package:gari_khata/ui/screens/office_report_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  for (final lang in ['en', 'bn']) {
    testWidgets('office claim lays out over A4 pages that can be captured ($lang)', (tester) async {
      SharedPreferences.setMockInitialValues({'lang': lang});
      late Directory dir;
      late AppState app;
      late Settings settings;
      late AuthService auth;
      await tester.runAsync(() async {
        dir = await Directory.systemTemp.createTemp('claim');
        final repo = await Repository.openWith(databaseFactoryFfi, '${dir.path}/p.db');
        app = AppState(repo, personal: true);
        settings = await Settings.load();
        auth = await AuthService.load(language: () => 'en');
        final car = await repo.saveVehicle(Vehicle(name: 'Axio', type: VehicleType.car, regNo: 'Dhaka Metro-Ga 34-5678', fuel: FuelType.cng));
        final now = DateTime.now();
        for (var d = 1; d <= 30; d++) {
          await repo.saveExpense(
            Expense(
              date: DateTime(now.year, now.month, 1),
              vehicleId: car,
              category: ExpenseCategory.toll,
              amount: 100.0 + d,
              note: 'Expressway $d',
              office: true,
            ),
          );
        }
        await repo.saveExpense(Expense(date: DateTime(now.year, now.month, 1), vehicleId: car, category: ExpenseCategory.wash, amount: 999));
        await app.refresh();
      });

      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: app),
          ],
          child: MaterialApp(theme: buildTheme(Palette.light), home: const OfficeReportScreen()),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }

      // 30 claimed rows: 14 on the first page, 16 on the second; the wash is not office.
      final pages = find
          .byType(RepaintBoundary)
          .evaluate()
          .map((e) => e.renderObject)
          .whereType<RenderRepaintBoundary>()
          .where((r) => r.size == const Size(595, 842))
          .toList();
      expect(pages.length, 2);
      expect(find.textContaining('Expressway 30'), findsOneWidget);
      expect(find.textContaining('999'), findsNothing);
      if (lang == 'en') {
        expect(find.text('Total claimed'), findsOneWidget);
        expect(find.text('৳3,465'), findsOneWidget); // 30 × 100 + (1 + … + 30)
      }

      await tester.runAsync(() async {
        final image = await pages.first.toImage(pixelRatio: 1);
        expect(image.width, 595);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(png!.lengthInBytes, greaterThan(1000));
        await dir.delete(recursive: true);
      });
    });
  }
}
