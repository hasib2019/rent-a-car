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

  tearDown(() async {
    // Windows will not delete a database file that is still open.
    await repo.close();
    await dir.delete(recursive: true);
  });

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

    final trips = await repo.trips();
    final done = trips.where((t) => t.trip.status == TripStatus.done);
    expect(done, isNotEmpty);
    expect(done.every((t) => t.cost > 0 && t.trip.fare > 0 && t.received > 0), isTrue);
    expect(trips.map((t) => t.trip.status).toSet(), containsAll([TripStatus.booked, TripStatus.running, TripStatus.done]));
    final statuses = await repo.partStatuses();
    expect(statuses.where((s) => s.health == DueHealth.overdue), isNotEmpty);
    expect(statuses.where((s) => s.health == DueHealth.soon), isNotEmpty);
    expect((await repo.serviceStatuses()).where((s) => s.needsAttention), isNotEmpty);
    expect((await repo.parties()).where((p) => p.due > 0), isNotEmpty);
    final visits = await repo.visits();
    expect(visits.where((v) => v.visit.kind == ServiceKind.official && v.partsCount > 0), isNotEmpty);
  });

  test('payments track what each party owes; bookings and cancellations earn nothing', () async {
    final v = await repo.saveVehicle(Vehicle(name: 'Axio', type: VehicleType.car));
    final day = DateTime(2026, 9, 10);
    final month = Period.month(day);
    final a = await repo.saveTrip(
      Trip(vehicleId: v, startDate: day, origin: 'Dhaka', destination: 'Sylhet', client: 'Rahman family', clientPhone: '01711', fare: 12000),
      [Expense(date: day, vehicleId: v, category: ExpenseCategory.commission, amount: 1000)],
      payments: [TripPayment(date: day, amount: 4000, method: PayMethod.bkash)],
    );
    await repo.saveTrip(Trip(vehicleId: v, startDate: day, origin: 'Mirpur', destination: 'Gazipur', client: '  rahman   FAMILY ', fare: 5000), [],
        payments: [TripPayment(date: day, amount: 5000)]);
    await repo.saveTrip(Trip(vehicleId: v, startDate: day, origin: 'A', destination: 'B', client: 'Rahman family', fare: 20000, status: TripStatus.booked), [],
        payments: [TripPayment(date: day, amount: 3000)]);
    await repo.saveTrip(Trip(vehicleId: v, startDate: day, origin: 'C', destination: 'D', client: 'Other', fare: 9000, status: TripStatus.cancelled), []);

    // Only the two trips that happened count as income.
    expect((await repo.totals(month)).income, 17000);
    final totals = await repo.tripTotals(month);
    expect(totals.count, 4);
    expect(totals.fare, 17000);
    expect(totals.due, 8000);

    final party = (await repo.parties()).firstWhere((p) => p.name == 'Rahman family');
    expect(party.trips, 3, reason: 'names match ignoring case and spaces');
    expect(party.fare, 17000);
    expect(party.received, 9000);
    expect(party.due, 8000);
    expect(party.phone, '01711');
    expect(await repo.clientPhone('RAHMAN family'), '01711');
    expect(await repo.suggestions('trips', 'client'), containsAll(['Rahman family', 'Other']));

    // Collecting the rest clears the due.
    await repo.addTripPayment(TripPayment(tripId: a, date: day.add(const Duration(days: 3)), amount: 8000, method: PayMethod.cash));
    expect((await repo.trips(onlyDue: true)), isEmpty);
    expect((await repo.tripPayments(a)).length, 2);

    // Saving the trip again without payments keeps them.
    await repo.saveTrip(Trip(id: a, vehicleId: v, startDate: day, origin: 'Dhaka', destination: 'Sylhet', client: 'Rahman family', fare: 12000), []);
    expect((await repo.tripPayments(a)).length, 2);
    await repo.deleteTrip(a);
    expect((await repo.parties()).firstWhere((p) => p.name == 'Rahman family').trips, 2);
  });

  test('a garage visit books labour and parts, and schedules the next service', () async {
    final v = await repo.saveVehicle(Vehicle(name: 'Pickup', type: VehicleType.pickup));
    final day = DateTime(2026, 8, 1);
    final visit = ServiceVisit(
      vehicleId: v,
      date: day,
      odometer: 60000,
      kind: ServiceKind.official,
      workshop: 'Service centre',
      jobNo: 'JC-1',
      title: '60,000 km service',
      labour: 2500,
      nextDate: DateTime(2026, 11, 1),
      nextKm: 65000,
    );
    final id = await repo.saveVisit(visit, [
      Part(vehicleId: 0, type: PartType.engineOil, installedDate: day, cost: 1800, qty: 4, shop: 'Haji Auto Parts', nextKm: 63000),
      Part(vehicleId: 0, type: PartType.clutchPlate, installedDate: day, cost: 4500, warrantyUntil: DateTime(2027, 2, 1)),
    ]);

    final summary = (await repo.visits()).single;
    expect(summary.partsCost, 6300);
    expect(summary.partsCount, 2);
    expect(summary.total, 8800);
    final parts = await repo.visitParts(id);
    expect(parts.every((p) => p.vehicleId == v && p.installedKm == 60000 && p.installedDate == day), isTrue);
    expect(parts.first.unitPrice, 450);
    expect(parts.first.shop, 'Haji Auto Parts');

    // Labour and both parts are in the ledger, all pointing back to the visit.
    final ledger = await repo.ledger(incomeOnly: false);
    expect(ledger.map((e) => e.amount), unorderedEquals([2500, 1800, 4500]));
    expect(ledger.every((e) => e.visitId == id && e.workshop == 'Service centre'), isTrue);
    expect((await repo.vehicleStats(Period.month(day)))[v]!.maintenance, 8800);

    // A later fuel reading puts the service 200 km overdue.
    await repo.saveExpense(Expense(date: DateTime(2026, 10, 1), vehicleId: v, category: ExpenseCategory.fuel, amount: 3000, quantity: 25, odometer: 65200));
    final due = (await repo.serviceStatuses()).single;
    expect(due.visit.id, id);
    expect(due.kmLeft, -200);
    expect(due.health, DueHealth.overdue);

    // Editing replaces the parts; deleting removes everything.
    await repo.saveVisit(ServiceVisit(id: id, vehicleId: v, date: day, odometer: 60000, labour: 1000), [
      Part(vehicleId: 0, type: PartType.airFilter, installedDate: day, cost: 600),
    ]);
    expect((await repo.ledger(incomeOnly: false)).where((e) => e.visitId == id).map((e) => e.amount), unorderedEquals([1000, 600]));
    expect(await repo.serviceStatuses(), isEmpty, reason: 'the edited visit no longer sets a schedule');
    await repo.deleteVisit(id);
    expect(await repo.parts(), isEmpty);
    expect((await repo.ledger(incomeOnly: false)).where((e) => e.category != 'fuel'), isEmpty);
  });

  test('a trip books its fare as income and its road costs as expenses', () async {
    final d = await repo.saveDriver(Driver(name: 'Kamal'));
    final v = await repo.saveVehicle(Vehicle(name: 'Pickup', type: VehicleType.pickup, driverId: d));
    final day = DateTime(2026, 10, 3);
    final trip = Trip(vehicleId: v, driverId: d, startDate: day, origin: 'Dhaka', destination: 'Chattogram', fare: 16000, startKm: 1000, endKm: 1540);
    final id = await repo.saveTrip(trip, [
      Expense(date: day, vehicleId: v, category: ExpenseCategory.fuel, amount: 5700, quantity: 50, place: 'Kanchpur'),
      Expense(date: day, vehicleId: v, category: ExpenseCategory.toll, amount: 350, place: 'Meghna bridge'),
      Expense(date: day, vehicleId: v, category: ExpenseCategory.mobil, amount: 650),
    ]);

    final summary = (await repo.trips()).single;
    expect(summary.cost, 6700);
    expect(summary.fuel, 5700);
    expect(summary.profit, 16000 - 6700);
    expect(summary.trip.distance, 540);

    final month = Period.month(day);
    final t = await repo.totals(month);
    expect(t.income, 16000);
    expect(t.expense, 6700);
    expect((await repo.vehicleStats(month))[v]!.maintenance, 650); // engine oil counts as upkeep
    expect((await repo.driverDues())[d], 0); // trip fares never create driver dues

    final rows = await repo.ledger(period: month);
    expect(rows.every((r) => r.tripId == id && r.route == 'Dhaka → Chattogram'), isTrue);
    expect(rows.firstWhere((r) => r.category == 'fuel').place, 'Kanchpur');
    expect((await repo.tripCosts(id)).firstWhere((c) => c.category == ExpenseCategory.fuel).odometer, 1540);

    // Editing replaces costs and updates the mirrored fare.
    await repo.saveTrip(Trip(id: id, vehicleId: v, startDate: day, origin: 'Dhaka', destination: 'Chattogram', fare: 15000), [
      Expense(date: day, vehicleId: v, category: ExpenseCategory.food, amount: 800),
    ]);
    final after = await repo.totals(month);
    expect(after.income, 15000);
    expect(after.expense, 800);

    await repo.deleteTrip(id);
    expect(await repo.trips(), isEmpty);
    expect(await repo.ledger(period: month), isEmpty);
  });

  test('part fittings track their cost and when they are due', () async {
    final v = await repo.saveVehicle(Vehicle(name: 'Axio', type: VehicleType.car));
    final today = DateTime(2026, 10, 7);
    final old = DateTime(2026, 5, 1);
    // An earlier oil change that has since been replaced.
    await repo.savePart(Part(vehicleId: v, type: PartType.engineOil, installedDate: old, installedKm: 40000, nextKm: 43000, cost: 2500));
    final oil = await repo.savePart(Part(
      vehicleId: v,
      type: PartType.engineOil,
      installedDate: DateTime(2026, 8, 1),
      installedKm: 50000,
      nextKm: 53000,
      nextDate: DateTime(2026, 11, 1),
      cost: 2800,
    ));
    await repo.savePart(Part(vehicleId: v, type: PartType.battery, installedDate: DateTime(2024, 10, 15), nextDate: DateTime(2026, 10, 15), cost: 0));
    await repo.saveExpense(Expense(date: DateTime(2026, 10, 6), vehicleId: v, category: ExpenseCategory.fuel, amount: 500, quantity: 12, odometer: 53200));

    expect((await repo.odometers())[v], 53200);
    final statuses = {
      for (final s in await repo.partStatuses()) s.part.type: PartStatus(s.part, currentKm: s.currentKm, today: today),
    };
    expect(statuses.length, 2, reason: 'the replaced oil change is history, not current');
    expect(statuses[PartType.engineOil]!.part.id, oil);
    expect(statuses[PartType.engineOil]!.kmLeft, -200);
    expect(statuses[PartType.engineOil]!.health, DueHealth.overdue);
    expect(statuses[PartType.engineOil]!.kmIsCloser, isTrue);
    expect(statuses[PartType.battery]!.daysLeft, 8);
    expect(statuses[PartType.battery]!.health, DueHealth.soon);

    // Fitting costs land in the ledger (zero-cost fittings do not).
    var costs = (await repo.ledger(incomeOnly: false)).where((e) => e.partId != null).toList();
    expect(costs.map((e) => e.amount), unorderedEquals([2500, 2800]));
    expect(costs.every((e) => e.partType == PartType.engineOil && e.category == 'mobil'), isTrue);

    await repo.deletePart(oil);
    costs = (await repo.ledger(incomeOnly: false)).where((e) => e.partId != null).toList();
    expect(costs.single.amount, 2500);
  });

  test('a version 1 database upgrades in place', () async {
    await repo.close();
    final path = '${dir.path}/v1.db';
    final v1 = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE drivers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, nid TEXT, license_no TEXT, address TEXT, join_date TEXT, opening_due REAL NOT NULL DEFAULT 0, active INTEGER NOT NULL DEFAULT 1, note TEXT, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE vehicles(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, reg_no TEXT, model TEXT, purchase_price REAL NOT NULL DEFAULT 0, purchase_date TEXT, daily_target REAL NOT NULL DEFAULT 0, driver_id INTEGER, status TEXT NOT NULL DEFAULT \'active\', note TEXT, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE incomes(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, vehicle_id INTEGER NOT NULL, driver_id INTEGER, kind TEXT NOT NULL, target REAL NOT NULL DEFAULT 0, amount REAL NOT NULL DEFAULT 0, note TEXT, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, vehicle_id INTEGER NOT NULL, category TEXT NOT NULL, amount REAL NOT NULL, quantity REAL, odometer REAL, note TEXT, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE papers(id INTEGER PRIMARY KEY AUTOINCREMENT, vehicle_id INTEGER NOT NULL, type TEXT NOT NULL, expiry_date TEXT NOT NULL, note TEXT)');
    }));
    await v1.insert('vehicles', {'name': 'Old CNG', 'type': 'cng', 'created_at': '2026-01-01'});
    await v1.insert('expenses', {'date': '2026-01-02', 'vehicle_id': 1, 'category': 'repair', 'amount': 900, 'created_at': '2026-01-02'});
    await v1.close();

    repo = await Repository.openWith(databaseFactoryFfi, path);
    expect((await repo.vehicles()).single.name, 'Old CNG');
    expect((await repo.ledger()).single.amount, 900);
    final id = await repo.saveTrip(Trip(vehicleId: 1, startDate: DateTime(2026, 1, 3), origin: 'A', destination: 'B', fare: 1000), []);
    expect((await repo.trip(id))!.fare, 1000);
    expect((await repo.counts())['trips'], 1);
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
