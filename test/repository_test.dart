import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gari_khata/core/catalog.dart';
import 'package:gari_khata/data/demo_seed.dart';
import 'package:gari_khata/data/models.dart';
import 'package:gari_khata/data/repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dir;
  late Repository repo;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('garikhata_test');
    repo = await Repository.openWith(databaseFactoryFfi, '${dir.path}/t.db');
  });

  tearDown(() => dir.delete(recursive: true));

  test('driver due = opening + shortfalls − recoveries', () async {
    final d = await repo.saveDriver(Driver(name: 'Rafiq', openingDue: 500));
    final v = await repo.saveVehicle(Vehicle(name: 'CNG', type: VehicleType.cng, dailyTarget: 1000, driverId: d));
    final day = DateTime(2026, 10, 1);
    await repo.saveIncome(Income(date: day, vehicleId: v, driverId: d, kind: IncomeKind.joma, target: 1000, amount: 700));
    await repo.saveIncome(Income(date: day.add(const Duration(days: 1)), vehicleId: v, driverId: d, kind: IncomeKind.joma, target: 1000, amount: 1000));
    await repo.saveIncome(Income(date: day.add(const Duration(days: 2)), vehicleId: v, driverId: d, kind: IncomeKind.due, amount: 300));
    await repo.saveIncome(Income(date: day.add(const Duration(days: 3)), vehicleId: v, driverId: d, kind: IncomeKind.trip, amount: 4000));
    expect((await repo.driverDues())[d], 500 + 300 - 300);

    await repo.saveExpense(Expense(date: day, vehicleId: v, category: ExpenseCategory.servicing, amount: 1200));
    final t = await repo.totals(Period(day, day.add(const Duration(days: 5))));
    expect(t.income, 700 + 1000 + 300 + 4000);
    expect(t.expense, 1200);
  });

  test('daily batch inserts, updates and removes', () async {
    final v1 = await repo.saveVehicle(Vehicle(name: 'A', type: VehicleType.cng, dailyTarget: 1000));
    final v2 = await repo.saveVehicle(Vehicle(name: 'B', type: VehicleType.car, dailyTarget: 1500));
    final day = DateTime(2026, 10, 7);
    await repo.saveDailyBatch([
      Income(date: day, vehicleId: v1, kind: IncomeKind.joma, target: 1000, amount: 1000),
      Income(date: day, vehicleId: v2, kind: IncomeKind.off, amount: 0),
    ], []);
    var map = await repo.dailyEntries(day);
    expect(map.length, 2);
    expect(map[v2]!.kind, IncomeKind.off);

    await repo.saveDailyBatch([
      Income(id: map[v1]!.id, date: day, vehicleId: v1, kind: IncomeKind.joma, target: 1000, amount: 800),
    ], [map[v2]!.id!]);
    map = await repo.dailyEntries(day);
    expect(map.length, 1);
    expect(map[v1]!.amount, 800);
  });

  test('demo seed produces a consistent ledger', () async {
    await seedDemoData(repo, bangla: true);
    final vehicles = await repo.vehicles();
    expect(vehicles.length, 4);
    final stats = await repo.vehicleStats(Period.allTime());
    final totals = await repo.totals(Period.allTime());
    final sumIncome = stats.values.fold<double>(0, (a, s) => a + s.income);
    final sumExpense = stats.values.fold<double>(0, (a, s) => a + s.expense);
    expect(sumIncome, closeTo(totals.income, 0.01));
    expect(sumExpense, closeTo(totals.expense, 0.01));
    expect(totals.profit, greaterThan(0));

    final monthly = await repo.monthly(months: 6);
    expect(monthly.length, 6);
    final ledger = await repo.ledger(limit: 10);
    expect(ledger.length, 10);
    expect(await repo.mileage(vehicles[2].id!), isNotNull);
  });

  test('export → erase → import restores everything', () async {
    await seedDemoData(repo, bangla: false);
    final before = await repo.counts();
    final bytes = await repo.exportBytes();
    expect(Repository.looksLikeSqlite(bytes), isTrue);

    await repo.eraseEverything();
    expect((await repo.counts())['incomes'], 0);

    await repo.importBytes(bytes);
    expect(await repo.counts(), before);
  });

  test('importing garbage keeps the current data', () async {
    await repo.saveVehicle(Vehicle(name: 'Keep me', type: VehicleType.pickup));
    await expectLater(repo.importBytes(Uint8List.fromList(List.filled(200, 7))), throwsFormatException);
    expect((await repo.vehicles()).single.name, 'Keep me');
  });
}
