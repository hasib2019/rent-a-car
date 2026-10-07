import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';

import '../core/catalog.dart';
import '../core/format.dart';
import 'db_factory.dart';
import 'models.dart';

/// Single source of truth for every query the app runs against SQLite.
class Repository {
  Repository._(this._factory, this._path, this._db);

  static const dbName = 'garikhata.db';

  /// 1: vehicles, drivers, incomes, expenses, papers.
  /// 2: trips and parts, linked into incomes/expenses.
  /// 3: garage visits, trip payments and business details, fuller vehicle,
  ///    driver, paper and part records.
  static const schemaVersion = 3;

  final DatabaseFactory _factory;
  final String _path;
  Database _db;

  static Future<Repository> open() async {
    final factory = platformDatabaseFactory();
    return openWith(factory, await databasePath(factory, dbName));
  }

  /// Opens a database with an explicit factory/path (used by tests).
  static Future<Repository> openWith(DatabaseFactory factory, String path) async =>
      Repository._(factory, path, await _openDb(factory, path));

  static Future<Database> _openDb(DatabaseFactory factory, String path) => factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, _) async {
            await _createSchema(db);
            await _upgradeTo2(db);
            await _upgradeTo3(db);
          },
          // Also runs when an older backup file is restored.
          onUpgrade: (db, from, _) async {
            if (from < 2) await _upgradeTo2(db);
            if (from < 3) await _upgradeTo3(db);
          },
        ),
      );

  Future<void> close() => _db.close();

  static Future<void> _createSchema(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE drivers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        nid TEXT,
        license_no TEXT,
        address TEXT,
        join_date TEXT,
        opening_due REAL NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        note TEXT,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        reg_no TEXT,
        model TEXT,
        purchase_price REAL NOT NULL DEFAULT 0,
        purchase_date TEXT,
        daily_target REAL NOT NULL DEFAULT 0,
        driver_id INTEGER REFERENCES drivers(id) ON DELETE SET NULL,
        status TEXT NOT NULL DEFAULT 'active',
        note TEXT,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE incomes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        driver_id INTEGER REFERENCES drivers(id) ON DELETE SET NULL,
        kind TEXT NOT NULL,
        target REAL NOT NULL DEFAULT 0,
        amount REAL NOT NULL DEFAULT 0,
        note TEXT,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        quantity REAL,
        odometer REAL,
        note TEXT,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE papers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        note TEXT
      )''');
    batch.execute('CREATE INDEX idx_incomes_date ON incomes(date)');
    batch.execute('CREATE INDEX idx_incomes_vehicle ON incomes(vehicle_id, date)');
    batch.execute('CREATE INDEX idx_incomes_driver ON incomes(driver_id, date)');
    batch.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    batch.execute('CREATE INDEX idx_expenses_vehicle ON expenses(vehicle_id, date)');
    await batch.commit(noResult: true);
  }

  static Future<void> _upgradeTo2(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        driver_id INTEGER REFERENCES drivers(id) ON DELETE SET NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        client TEXT,
        fare REAL NOT NULL DEFAULT 0,
        start_km REAL,
        end_km REAL,
        note TEXT,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE parts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        detail TEXT,
        installed_date TEXT NOT NULL,
        installed_km REAL,
        cost REAL NOT NULL DEFAULT 0,
        next_date TEXT,
        next_km REAL,
        note TEXT,
        created_at TEXT NOT NULL
      )''');
    batch.execute('ALTER TABLE incomes ADD COLUMN trip_id INTEGER REFERENCES trips(id) ON DELETE CASCADE');
    batch.execute('ALTER TABLE expenses ADD COLUMN trip_id INTEGER REFERENCES trips(id) ON DELETE CASCADE');
    batch.execute('ALTER TABLE expenses ADD COLUMN part_id INTEGER REFERENCES parts(id) ON DELETE CASCADE');
    batch.execute('ALTER TABLE expenses ADD COLUMN place TEXT');
    batch.execute('CREATE INDEX idx_trips_vehicle ON trips(vehicle_id, start_date)');
    batch.execute('CREATE INDEX idx_parts_vehicle ON parts(vehicle_id, type)');
    batch.execute('CREATE INDEX idx_incomes_trip ON incomes(trip_id)');
    batch.execute('CREATE INDEX idx_expenses_trip ON expenses(trip_id)');
    batch.execute('CREATE INDEX idx_expenses_part ON expenses(part_id)');
    await batch.commit(noResult: true);
  }

  static Future<void> _upgradeTo3(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE service_visits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        date TEXT NOT NULL,
        odometer REAL,
        kind TEXT NOT NULL DEFAULT 'local',
        workshop TEXT,
        mechanic TEXT,
        job_no TEXT,
        title TEXT,
        labour REAL NOT NULL DEFAULT 0,
        next_date TEXT,
        next_km REAL,
        note TEXT,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE trip_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL DEFAULT 'cash',
        note TEXT,
        created_at TEXT NOT NULL
      )''');
    for (final col in ['chassis_no TEXT', 'engine_no TEXT', 'color TEXT', 'year INTEGER', 'fuel TEXT', 'capacity TEXT']) {
      batch.execute('ALTER TABLE vehicles ADD COLUMN $col');
    }
    batch.execute('ALTER TABLE drivers ADD COLUMN license_expiry TEXT');
    batch.execute('ALTER TABLE papers ADD COLUMN doc_no TEXT');
    batch.execute('ALTER TABLE papers ADD COLUMN provider TEXT');
    for (final col in ['client_phone TEXT', "status TEXT NOT NULL DEFAULT 'done'", 'goods TEXT', 'challan_no TEXT']) {
      batch.execute('ALTER TABLE trips ADD COLUMN $col');
    }
    batch.execute('ALTER TABLE parts ADD COLUMN visit_id INTEGER REFERENCES service_visits(id) ON DELETE CASCADE');
    batch.execute('ALTER TABLE parts ADD COLUMN shop TEXT');
    batch.execute('ALTER TABLE parts ADD COLUMN qty REAL NOT NULL DEFAULT 1');
    batch.execute('ALTER TABLE parts ADD COLUMN warranty_until TEXT');
    batch.execute('ALTER TABLE expenses ADD COLUMN visit_id INTEGER REFERENCES service_visits(id) ON DELETE CASCADE');
    batch.execute('CREATE INDEX idx_visits_vehicle ON service_visits(vehicle_id, date)');
    batch.execute('CREATE INDEX idx_payments_trip ON trip_payments(trip_id)');
    batch.execute('CREATE INDEX idx_parts_visit ON parts(visit_id)');
    batch.execute('CREATE INDEX idx_expenses_visit ON expenses(visit_id)');
    await batch.commit(noResult: true);
  }

  // ── Backup / restore ────────────────────────────────────────────────────

  /// Raw SQLite file bytes — identical on every platform.
  Future<Uint8List> exportBytes() async {
    // Flush WAL pages into the main file so the copy is complete.
    try {
      await _db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    } catch (_) {}
    return _factory.readDatabaseBytes(_path);
  }

  static bool looksLikeSqlite(Uint8List bytes) {
    const header = 'SQLite format 3';
    if (bytes.length < 100) return false;
    for (var i = 0; i < header.length; i++) {
      if (bytes[i] != header.codeUnitAt(i)) return false;
    }
    return true;
  }

  /// Replaces the live database with [bytes]. The previous file is restored if
  /// the new one turns out not to be a GariKhata backup.
  Future<void> importBytes(Uint8List bytes) async {
    if (!looksLikeSqlite(bytes)) throw const FormatException('not sqlite');
    final previous = await exportBytes();
    await _db.close();
    try {
      await _factory.writeDatabaseBytes(_path, bytes);
      _db = await _openDb(_factory, _path);
      final tables = await _db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final names = tables.map((r) => r['name']).toSet();
      if (!names.containsAll(['vehicles', 'drivers', 'incomes', 'expenses'])) {
        throw const FormatException('missing tables');
      }
    } catch (e) {
      try {
        await _db.close();
      } catch (_) {}
      await _factory.writeDatabaseBytes(_path, previous);
      _db = await _openDb(_factory, _path);
      rethrow;
    }
  }

  Future<void> eraseEverything() async {
    await _db.transaction((txn) async {
      for (final t in ['papers', 'expenses', 'incomes', 'trip_payments', 'parts', 'service_visits', 'trips', 'vehicles', 'drivers']) {
        await txn.delete(t);
      }
      await txn.execute("DELETE FROM sqlite_sequence");
    });
  }

  Future<Map<String, int>> counts() async {
    final out = <String, int>{};
    for (final t in ['vehicles', 'drivers', 'incomes', 'expenses', 'papers', 'trips', 'parts', 'service_visits']) {
      final r = await _db.rawQuery('SELECT COUNT(*) AS c FROM $t');
      out[t] = (r.first['c'] as int?) ?? 0;
    }
    return out;
  }

  // ── Generic helpers ─────────────────────────────────────────────────────

  Future<int> _upsert(String table, Map<String, Object?> map) async {
    final id = map['id'] as int?;
    if (id == null) {
      map.remove('id');
      return _db.insert(table, map);
    }
    map.remove('created_at');
    await _db.update(table, map, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  // ── Drivers ─────────────────────────────────────────────────────────────

  Future<List<Driver>> drivers() async {
    final rows = await _db.query('drivers', orderBy: 'active DESC, name COLLATE NOCASE');
    return rows.map(Driver.fromMap).toList();
  }

  Future<int> saveDriver(Driver d) => _upsert('drivers', d.toMap());

  Future<void> deleteDriver(int id) => _db.delete('drivers', where: 'id = ?', whereArgs: [id]);

  // ── Vehicles ────────────────────────────────────────────────────────────

  Future<List<Vehicle>> vehicles() async {
    final rows = await _db.query('vehicles', orderBy: "CASE status WHEN 'active' THEN 0 WHEN 'garage' THEN 1 ELSE 2 END, id");
    return rows.map(Vehicle.fromMap).toList();
  }

  Future<int> saveVehicle(Vehicle v) => _upsert('vehicles', v.toMap());

  Future<void> deleteVehicle(int id) => _db.delete('vehicles', where: 'id = ?', whereArgs: [id]);

  // ── Incomes / expenses ──────────────────────────────────────────────────

  Future<int> saveIncome(Income i) => _upsert('incomes', i.toMap());
  Future<int> saveExpense(Expense e) => _upsert('expenses', e.toMap());
  Future<void> deleteIncome(int id) => _db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteExpense(int id) => _db.delete('expenses', where: 'id = ?', whereArgs: [id]);

  Future<Income?> income(int id) async {
    final r = await _db.query('incomes', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Income.fromMap(r.first);
  }

  Future<Expense?> expense(int id) async {
    final r = await _db.query('expenses', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Expense.fromMap(r.first);
  }

  /// Daily-collection (or off-day) entries for [date], keyed by vehicle.
  Future<Map<int, Income>> dailyEntries(DateTime date) async {
    final rows = await _db.query('incomes',
        where: "date = ? AND kind IN ('joma','off')", whereArgs: [dbDate(date)], orderBy: 'id');
    return {for (final r in rows) r['vehicle_id'] as int: Income.fromMap(r)};
  }

  /// Saves a whole day's collection in one transaction. Entries with an id are
  /// updated; [removeIds] are deleted (e.g. a vehicle that was un-marked).
  Future<void> saveDailyBatch(List<Income> entries, List<int> removeIds) async {
    await _db.transaction((txn) async {
      for (final id in removeIds) {
        await txn.delete('incomes', where: 'id = ?', whereArgs: [id]);
      }
      for (final e in entries) {
        final m = e.toMap();
        if (e.id == null) {
          m.remove('id');
          await txn.insert('incomes', m);
        } else {
          m.remove('created_at');
          await txn.update('incomes', m, where: 'id = ?', whereArgs: [e.id]);
        }
      }
    });
  }

  /// Combined, newest-first ledger.
  Future<List<LedgerEntry>> ledger({
    Period? period,
    int? vehicleId,
    int? driverId,
    bool? incomeOnly,
    int? limit,
  }) async {
    final iWhere = <String>["kind != 'off'"];
    final eWhere = <String>['1=1'];
    final iArgs = <Object?>[];
    final eArgs = <Object?>[];
    if (period != null) {
      iWhere.add('date BETWEEN ? AND ?');
      eWhere.add('date BETWEEN ? AND ?');
      iArgs.addAll([dbDate(period.from), dbDate(period.to)]);
      eArgs.addAll([dbDate(period.from), dbDate(period.to)]);
    }
    if (vehicleId != null) {
      iWhere.add('vehicle_id = ?');
      eWhere.add('vehicle_id = ?');
      iArgs.add(vehicleId);
      eArgs.add(vehicleId);
    }
    if (driverId != null) {
      iWhere.add('driver_id = ?');
      iArgs.add(driverId);
    }
    final parts = <String>[];
    final args = <Object?>[];
    const route = "(SELECT t.origin || ' → ' || t.destination FROM trips t WHERE t.id = trip_id) AS route";
    // A part fitted during a garage visit belongs to that visit.
    const visit = 'COALESCE(visit_id, (SELECT p.visit_id FROM parts p WHERE p.id = part_id))';
    if (incomeOnly != false) {
      parts.add("SELECT 'i' AS src, id, date, vehicle_id, driver_id, kind AS cat, amount, target, NULL AS quantity, note, created_at, "
          'NULL AS place, trip_id, $route, NULL AS part_id, NULL AS part_type, NULL AS visit_id, NULL AS workshop FROM incomes WHERE ${iWhere.join(' AND ')}');
      args.addAll(iArgs);
    }
    if (incomeOnly != true && driverId == null) {
      parts.add("SELECT 'e' AS src, id, date, vehicle_id, NULL AS driver_id, category AS cat, amount, 0 AS target, quantity, note, created_at, "
          'place, trip_id, $route, part_id, (SELECT p.type FROM parts p WHERE p.id = part_id) AS part_type, '
          '$visit AS visit_id, (SELECT v.workshop FROM service_visits v WHERE v.id = $visit) AS workshop '
          'FROM expenses WHERE ${eWhere.join(' AND ')}');
      args.addAll(eArgs);
    }
    if (parts.isEmpty) return [];
    final sql = '${parts.join(' UNION ALL ')} ORDER BY date DESC, created_at DESC${limit != null ? ' LIMIT $limit' : ''}';
    final rows = await _db.rawQuery(sql, args);
    return rows.map(LedgerEntry.fromMap).toList();
  }

  // ── Aggregates ──────────────────────────────────────────────────────────

  Future<Totals> totals(Period p, {int? vehicleId}) async {
    final vf = vehicleId == null ? '' : ' AND vehicle_id = $vehicleId';
    final args = [dbDate(p.from), dbDate(p.to)];
    final i = await _db.rawQuery('SELECT COALESCE(SUM(amount),0) AS s FROM incomes WHERE date BETWEEN ? AND ?$vf', args);
    final e = await _db.rawQuery('SELECT COALESCE(SUM(amount),0) AS s FROM expenses WHERE date BETWEEN ? AND ?$vf', args);
    return Totals(income: (i.first['s'] as num).toDouble(), expense: (e.first['s'] as num).toDouble());
  }

  Future<Map<int, VehicleStat>> vehicleStats(Period p) async {
    final args = [dbDate(p.from), dbDate(p.to)];
    final out = <int, VehicleStat>{};
    VehicleStat of(int id) => out.putIfAbsent(id, () => VehicleStat(vehicleId: id));

    final inc = await _db.rawQuery('''
      SELECT vehicle_id, SUM(amount) AS s,
             COUNT(DISTINCT CASE WHEN kind IN ('joma','trip') AND amount > 0 THEN date END) AS d
      FROM incomes WHERE date BETWEEN ? AND ? GROUP BY vehicle_id''', args);
    for (final r in inc) {
      final s = of(r['vehicle_id'] as int);
      s.income = (r['s'] as num).toDouble();
      s.activeDays = (r['d'] as int?) ?? 0;
    }
    final exp = await _db.rawQuery('''
      SELECT vehicle_id, category, SUM(amount) AS s
      FROM expenses WHERE date BETWEEN ? AND ? GROUP BY vehicle_id, category''', args);
    for (final r in exp) {
      final s = of(r['vehicle_id'] as int);
      final amt = (r['s'] as num).toDouble();
      final cat = ExpenseCategory.from(r['category'] as String?);
      s.expense += amt;
      if (cat == ExpenseCategory.fuel) s.fuel += amt;
      if (cat.isMaintenance) s.maintenance += amt;
    }
    return out;
  }

  /// Income vs expense per calendar month, oldest first.
  Future<List<MonthPoint>> monthly({int months = 6, int? vehicleId, DateTime? until}) async {
    final end = until ?? DateTime.now();
    final points = [for (var i = months - 1; i >= 0; i--) MonthPoint(DateTime(end.year, end.month - i, 1))];
    final from = dbDate(points.first.month);
    final to = dbDate(DateTime(end.year, end.month + 1, 0));
    final vf = vehicleId == null ? '' : ' AND vehicle_id = $vehicleId';
    final byKey = {for (final p in points) '${p.month.year}-${p.month.month.toString().padLeft(2, '0')}': p};

    final inc = await _db.rawQuery('SELECT substr(date,1,7) AS m, SUM(amount) AS s FROM incomes WHERE date BETWEEN ? AND ?$vf GROUP BY m', [from, to]);
    for (final r in inc) {
      byKey[r['m']]?.income = (r['s'] as num).toDouble();
    }
    final exp = await _db.rawQuery('SELECT substr(date,1,7) AS m, SUM(amount) AS s FROM expenses WHERE date BETWEEN ? AND ?$vf GROUP BY m', [from, to]);
    for (final r in exp) {
      byKey[r['m']]?.expense = (r['s'] as num).toDouble();
    }
    return points;
  }

  /// Net profit per day for a sparkline.
  Future<List<double>> dailyProfit(Period p) async {
    final days = p.lengthInDays;
    final out = List<double>.filled(days, 0);
    final args = [dbDate(p.from), dbDate(p.to)];
    final inc = await _db.rawQuery('SELECT date, SUM(amount) AS s FROM incomes WHERE date BETWEEN ? AND ? GROUP BY date', args);
    final exp = await _db.rawQuery('SELECT date, SUM(amount) AS s FROM expenses WHERE date BETWEEN ? AND ? GROUP BY date', args);
    for (final r in inc) {
      final i = parseDbDate(r['date'] as String).difference(p.from).inDays;
      if (i >= 0 && i < days) out[i] += (r['s'] as num).toDouble();
    }
    for (final r in exp) {
      final i = parseDbDate(r['date'] as String).difference(p.from).inDays;
      if (i >= 0 && i < days) out[i] -= (r['s'] as num).toDouble();
    }
    return out;
  }

  Future<Map<ExpenseCategory, double>> expenseByCategory(Period p, {int? vehicleId}) async {
    final vf = vehicleId == null ? '' : ' AND vehicle_id = $vehicleId';
    final rows = await _db.rawQuery(
        'SELECT category, SUM(amount) AS s FROM expenses WHERE date BETWEEN ? AND ?$vf GROUP BY category ORDER BY s DESC',
        [dbDate(p.from), dbDate(p.to)]);
    return {for (final r in rows) ExpenseCategory.from(r['category'] as String?): (r['s'] as num).toDouble()};
  }

  /// Outstanding due per driver: opening due + Σ(target − paid) over daily
  /// collections and due recoveries. Negative means paid in advance.
  Future<Map<int, double>> driverDues() async {
    final rows = await _db.rawQuery('''
      SELECT d.id, d.opening_due + COALESCE(SUM(i.target - i.amount), 0) AS due
      FROM drivers d
      LEFT JOIN incomes i ON i.driver_id = d.id AND i.kind IN ('joma','due')
      GROUP BY d.id''');
    return {for (final r in rows) r['id'] as int: (r['due'] as num).toDouble()};
  }

  Future<Map<DateTime, DayRecord>> driverDays(int driverId, Period p) async {
    final rows = await _db.rawQuery('''
      SELECT date, kind, SUM(target) AS t, SUM(amount) AS a FROM incomes
      WHERE driver_id = ? AND date BETWEEN ? AND ? AND kind IN ('joma','off')
      GROUP BY date, kind''', [driverId, dbDate(p.from), dbDate(p.to)]);
    final out = <DateTime, DayRecord>{};
    for (final r in rows) {
      final d = out.putIfAbsent(parseDbDate(r['date'] as String), DayRecord.new);
      if (r['kind'] == 'off') {
        d.off = true;
      } else {
        d.target += (r['t'] as num).toDouble();
        d.amount += (r['a'] as num).toDouble();
      }
    }
    return out;
  }

  Future<({double paid, int days})> driverTotals(int driverId, Period p) async {
    final r = await _db.rawQuery('''
      SELECT COALESCE(SUM(amount),0) AS a, COUNT(DISTINCT CASE WHEN kind = 'joma' AND amount > 0 THEN date END) AS d
      FROM incomes WHERE driver_id = ? AND date BETWEEN ? AND ?''', [driverId, dbDate(p.from), dbDate(p.to)]);
    return (paid: (r.first['a'] as num).toDouble(), days: (r.first['d'] as int?) ?? 0);
  }

  /// Average km per litre/m³ from fuel entries that carry odometer readings.
  Future<double?> mileage(int vehicleId) async {
    final rows = await _db.rawQuery('''
      SELECT odometer, quantity FROM expenses
      WHERE vehicle_id = ? AND category = 'fuel' AND odometer IS NOT NULL AND quantity IS NOT NULL AND quantity > 0
      ORDER BY odometer''', [vehicleId]);
    if (rows.length < 2) return null;
    final first = (rows.first['odometer'] as num).toDouble();
    final last = (rows.last['odometer'] as num).toDouble();
    var qty = 0.0;
    for (final r in rows.skip(1)) {
      qty += (r['quantity'] as num).toDouble();
    }
    if (qty <= 0 || last <= first) return null;
    return (last - first) / qty;
  }

  // ── Papers ──────────────────────────────────────────────────────────────

  Future<List<Paper>> papers({int? vehicleId}) async {
    final rows = await _db.query('papers',
        where: vehicleId == null ? null : 'vehicle_id = ?',
        whereArgs: vehicleId == null ? null : [vehicleId],
        orderBy: 'expiry_date');
    return rows.map(Paper.fromMap).toList();
  }

  Future<int> savePaper(Paper p) => _upsert('papers', p.toMap());
  Future<void> deletePaper(int id) => _db.delete('papers', where: 'id = ?', whereArgs: [id]);

  // ── Trips ───────────────────────────────────────────────────────────────

  /// Trips with their summed road costs and payments, newest first.
  Future<List<TripSummary>> trips({Period? period, int? vehicleId, int? limit, bool onlyDue = false}) async {
    final where = <String>['1=1'];
    final args = <Object?>[];
    if (period != null) {
      where.add('t.start_date BETWEEN ? AND ?');
      args.addAll([dbDate(period.from), dbDate(period.to)]);
    }
    if (vehicleId != null) {
      where.add('t.vehicle_id = ?');
      args.add(vehicleId);
    }
    if (onlyDue) where.add("t.status IN ${TripStatus.earningKeys} AND t.fare - COALESCE(p.paid, 0) > 0.5");
    final rows = await _db.rawQuery('''
      SELECT t.*, COALESCE(c.cost, 0) AS cost_sum, COALESCE(c.fuel, 0) AS fuel_sum, COALESCE(p.paid, 0) AS paid_sum
      FROM trips t
      LEFT JOIN (
        SELECT trip_id, SUM(amount) AS cost, SUM(CASE WHEN category = 'fuel' THEN amount ELSE 0 END) AS fuel
        FROM expenses WHERE trip_id IS NOT NULL GROUP BY trip_id
      ) c ON c.trip_id = t.id
      LEFT JOIN (SELECT trip_id, SUM(amount) AS paid FROM trip_payments GROUP BY trip_id) p ON p.trip_id = t.id
      WHERE ${where.join(' AND ')}
      ORDER BY t.start_date DESC, t.id DESC${limit != null ? ' LIMIT $limit' : ''}''', args);
    return [
      for (final r in rows)
        TripSummary(
          Trip.fromMap(r),
          cost: (r['cost_sum'] as num).toDouble(),
          fuel: (r['fuel_sum'] as num).toDouble(),
          received: (r['paid_sum'] as num).toDouble(),
        ),
    ];
  }

  Future<List<TripPayment>> tripPayments(int tripId) async {
    final rows = await _db.query('trip_payments', where: 'trip_id = ?', whereArgs: [tripId], orderBy: 'date, id');
    return rows.map(TripPayment.fromMap).toList();
  }

  /// Records one more payment from the party against a trip.
  Future<int> addTripPayment(TripPayment p) => _db.insert('trip_payments', p.toMap()..remove('id'));

  Future<void> deleteTripPayment(int id) => _db.delete('trip_payments', where: 'id = ?', whereArgs: [id]);

  /// Every client with their trips, fares and what they still owe, biggest due first.
  Future<List<PartySummary>> parties() async {
    final rows = await _db.rawQuery('''
      SELECT t.client, t.client_phone, t.start_date, t.status, t.fare, COALESCE(p.paid, 0) AS paid
      FROM trips t
      LEFT JOIN (SELECT trip_id, SUM(amount) AS paid FROM trip_payments GROUP BY trip_id) p ON p.trip_id = t.id
      WHERE t.client IS NOT NULL AND trim(t.client) != ''
      ORDER BY t.start_date, t.id''');
    final out = <String, PartySummary>{};
    for (final r in rows) {
      final name = (r['client'] as String).trim().replaceAll(RegExp(r'\s+'), ' ');
      final party = out.putIfAbsent(PartySummary.keyOf(name), () => PartySummary(name: name))..name = name;
      final phone = r['client_phone'] as String?;
      if (phone != null && phone.trim().isNotEmpty) party.phone = phone.trim();
      party.trips++;
      party.lastTrip = parseDbDate(r['start_date'] as String);
      if (TripStatus.from(r['status'] as String?).countsFare) {
        party.fare += (r['fare'] as num).toDouble();
        party.received += (r['paid'] as num).toDouble();
      }
    }
    return out.values.toList()..sort((a, b) => b.due.compareTo(a.due));
  }

  /// Distinct values already typed into a text column, newest first (for suggestions).
  Future<List<String>> suggestions(String table, String column) async {
    final rows = await _db.rawQuery(
        "SELECT $column AS v, MAX(id) AS last FROM $table WHERE $column IS NOT NULL AND trim($column) != '' GROUP BY lower(trim($column)) ORDER BY last DESC LIMIT 50");
    return [for (final r in rows) (r['v'] as String).trim()];
  }

  /// Phone last used for a client, to fill it in when the name is picked again.
  Future<String?> clientPhone(String client) async {
    final rows = await _db.rawQuery(
        "SELECT client_phone FROM trips WHERE lower(trim(client)) = ? AND client_phone IS NOT NULL AND trim(client_phone) != '' ORDER BY id DESC LIMIT 1",
        [PartySummary.keyOf(client)]);
    return rows.isEmpty ? null : rows.first['client_phone'] as String?;
  }

  Future<Trip?> trip(int id) async {
    final r = await _db.query('trips', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Trip.fromMap(r.first);
  }

  Future<List<Expense>> tripCosts(int tripId) async {
    final rows = await _db.query('expenses', where: 'trip_id = ?', whereArgs: [tripId], orderBy: 'id');
    return rows.map(Expense.fromMap).toList();
  }

  /// Saves a trip with its fare (as a `trip` income) and replaces its costs,
  /// and its payments too when [payments] is given.
  Future<int> saveTrip(Trip t, List<Expense> costs, {List<TripPayment>? payments}) => _db.transaction((txn) async {
        final m = t.toMap();
        final int id;
        if (t.id == null) {
          m.remove('id');
          id = await txn.insert('trips', m);
        } else {
          m.remove('created_at');
          await txn.update('trips', m, where: 'id = ?', whereArgs: [t.id]);
          id = t.id!;
        }

        final fareRows = await txn.query('incomes', columns: ['id'], where: 'trip_id = ?', whereArgs: [id]);
        if (t.earned > 0) {
          final income = Income(
            date: t.startDate,
            vehicleId: t.vehicleId,
            driverId: t.driverId,
            kind: IncomeKind.trip,
            amount: t.earned,
            note: t.client?.isNotEmpty == true ? '${t.route} · ${t.client}' : t.route,
            tripId: id,
          ).toMap()
            ..remove('id');
          if (fareRows.isEmpty) {
            await txn.insert('incomes', income);
          } else {
            income.remove('created_at');
            await txn.update('incomes', income, where: 'id = ?', whereArgs: [fareRows.first['id']]);
          }
        } else if (fareRows.isNotEmpty) {
          await txn.delete('incomes', where: 'trip_id = ?', whereArgs: [id]);
        }

        await txn.delete('expenses', where: 'trip_id = ?', whereArgs: [id]);
        for (final c in costs) {
          if (c.amount <= 0) continue;
          await txn.insert(
            'expenses',
            Expense(
              date: t.startDate,
              vehicleId: t.vehicleId,
              category: c.category,
              amount: c.amount,
              quantity: c.quantity,
              // Fuel bought on the trip lands on the end reading for mileage.
              odometer: c.category == ExpenseCategory.fuel && c.quantity != null ? t.endKm : null,
              note: c.note,
              place: c.place,
              tripId: id,
            ).toMap()
              ..remove('id'),
          );
        }

        if (payments != null) {
          await txn.delete('trip_payments', where: 'trip_id = ?', whereArgs: [id]);
          for (final p in payments) {
            if (p.amount <= 0) continue;
            await txn.insert('trip_payments', TripPayment(tripId: id, date: p.date, amount: p.amount, method: p.method, note: p.note).toMap()..remove('id'));
          }
        }
        return id;
      });

  Future<void> deleteTrip(int id) => _db.transaction((txn) async {
        await txn.delete('incomes', where: 'trip_id = ?', whereArgs: [id]);
        await txn.delete('expenses', where: 'trip_id = ?', whereArgs: [id]);
        await txn.delete('trip_payments', where: 'trip_id = ?', whereArgs: [id]);
        await txn.delete('trips', where: 'id = ?', whereArgs: [id]);
      });

  Future<({int count, double fare, double cost, double due})> tripTotals(Period p) async {
    final args = [dbDate(p.from), dbDate(p.to)];
    final t = await _db.rawQuery('''
      SELECT COUNT(*) AS n,
             COALESCE(SUM(CASE WHEN t.status IN ${TripStatus.earningKeys} THEN t.fare ELSE 0 END), 0) AS f,
             COALESCE(SUM(CASE WHEN t.status IN ${TripStatus.earningKeys} THEN t.fare - COALESCE(p.paid, 0) ELSE 0 END), 0) AS d
      FROM trips t
      LEFT JOIN (SELECT trip_id, SUM(amount) AS paid FROM trip_payments GROUP BY trip_id) p ON p.trip_id = t.id
      WHERE t.start_date BETWEEN ? AND ?''', args);
    final c = await _db.rawQuery('''
      SELECT COALESCE(SUM(e.amount),0) AS c FROM expenses e JOIN trips t ON t.id = e.trip_id
      WHERE t.start_date BETWEEN ? AND ?''', args);
    return (
      count: (t.first['n'] as int?) ?? 0,
      fare: (t.first['f'] as num).toDouble(),
      cost: (c.first['c'] as num).toDouble(),
      due: (t.first['d'] as num).toDouble(),
    );
  }

  // ── Garage / service visits ─────────────────────────────────────────────

  /// Visits with their parts bill, newest first.
  Future<List<VisitSummary>> visits({int? vehicleId, Period? period, int? limit}) async {
    final where = <String>['1=1'];
    final args = <Object?>[];
    if (vehicleId != null) {
      where.add('v.vehicle_id = ?');
      args.add(vehicleId);
    }
    if (period != null) {
      where.add('v.date BETWEEN ? AND ?');
      args.addAll([dbDate(period.from), dbDate(period.to)]);
    }
    final rows = await _db.rawQuery('''
      SELECT v.*, COALESCE(p.cost, 0) AS parts_cost, COALESCE(p.n, 0) AS parts_n
      FROM service_visits v
      LEFT JOIN (SELECT visit_id, SUM(cost) AS cost, COUNT(*) AS n FROM parts WHERE visit_id IS NOT NULL GROUP BY visit_id) p ON p.visit_id = v.id
      WHERE ${where.join(' AND ')}
      ORDER BY v.date DESC, v.id DESC${limit != null ? ' LIMIT $limit' : ''}''', args);
    return [
      for (final r in rows)
        VisitSummary(ServiceVisit.fromMap(r), partsCost: (r['parts_cost'] as num).toDouble(), partsCount: (r['parts_n'] as int?) ?? 0),
    ];
  }

  Future<ServiceVisit?> visit(int id) async {
    final r = await _db.query('service_visits', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : ServiceVisit.fromMap(r.first);
  }

  Future<List<Part>> visitParts(int visitId) async {
    final rows = await _db.query('parts', where: 'visit_id = ?', whereArgs: [visitId], orderBy: 'id');
    return rows.map(Part.fromMap).toList();
  }

  /// Saves a job card: the visit, its labour bill and every part fitted
  /// (each part also lands in the ledger and in the replacement reminders).
  Future<int> saveVisit(ServiceVisit v, List<Part> parts) => _db.transaction((txn) async {
        final m = v.toMap();
        final int id;
        if (v.id == null) {
          m.remove('id');
          id = await txn.insert('service_visits', m);
        } else {
          m.remove('created_at');
          await txn.update('service_visits', m, where: 'id = ?', whereArgs: [v.id]);
          id = v.id!;
        }

        await txn.delete('expenses', where: 'visit_id = ?', whereArgs: [id]);
        if (v.labour > 0) {
          await txn.insert(
            'expenses',
            Expense(
              date: v.date,
              vehicleId: v.vehicleId,
              category: ExpenseCategory.servicing,
              amount: v.labour,
              odometer: v.odometer,
              note: v.title,
              visitId: id,
            ).toMap()
              ..remove('id'),
          );
        }

        await txn.rawDelete('DELETE FROM expenses WHERE part_id IN (SELECT id FROM parts WHERE visit_id = ?)', [id]);
        await txn.delete('parts', where: 'visit_id = ?', whereArgs: [id]);
        for (final p in parts) {
          final part = Part(
            vehicleId: v.vehicleId,
            type: p.type,
            detail: p.detail,
            installedDate: v.date,
            installedKm: v.odometer,
            cost: p.cost,
            nextDate: p.nextDate,
            nextKm: p.nextKm,
            note: p.note,
            visitId: id,
            shop: p.shop,
            qty: p.qty,
            warrantyUntil: p.warrantyUntil,
          );
          final partId = await txn.insert('parts', part.toMap()..remove('id'));
          if (part.cost > 0) await txn.insert('expenses', _partExpense(part, partId)..remove('id'));
        }
        return id;
      });

  Future<void> deleteVisit(int id) => _db.transaction((txn) async {
        await txn.delete('expenses', where: 'visit_id = ?', whereArgs: [id]);
        await txn.rawDelete('DELETE FROM expenses WHERE part_id IN (SELECT id FROM parts WHERE visit_id = ?)', [id]);
        await txn.delete('parts', where: 'visit_id = ?', whereArgs: [id]);
        await txn.delete('service_visits', where: 'id = ?', whereArgs: [id]);
      });

  /// Each vehicle's next general service, from its latest visit that set one.
  Future<List<ServiceStatus>> serviceStatuses({int? vehicleId}) async {
    final rows = await _db.rawQuery('''
      SELECT * FROM service_visits
      WHERE (next_date IS NOT NULL OR next_km IS NOT NULL)${vehicleId == null ? '' : ' AND vehicle_id = $vehicleId'}
      ORDER BY date DESC, id DESC''');
    final km = await odometers();
    final latest = <int, ServiceVisit>{};
    for (final r in rows) {
      final v = ServiceVisit.fromMap(r);
      latest.putIfAbsent(v.vehicleId, () => v);
    }
    return _byUrgency([for (final v in latest.values) ServiceStatus(v, currentKm: km[v.vehicleId])]);
  }

  // ── Parts ───────────────────────────────────────────────────────────────

  /// Every fitting, newest first.
  Future<List<Part>> parts({int? vehicleId, Period? period}) async {
    final where = <String>['1=1'];
    final args = <Object?>[];
    if (vehicleId != null) {
      where.add('vehicle_id = ?');
      args.add(vehicleId);
    }
    if (period != null) {
      where.add('installed_date BETWEEN ? AND ?');
      args.addAll([dbDate(period.from), dbDate(period.to)]);
    }
    final rows = await _db.query('parts', where: where.join(' AND '), whereArgs: args, orderBy: 'installed_date DESC, id DESC');
    return rows.map(Part.fromMap).toList();
  }

  Future<Part?> part(int id) async {
    final r = await _db.query('parts', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Part.fromMap(r.first);
  }

  /// Saves a fitting and keeps its cost in the ledger as an expense.
  Future<int> savePart(Part p) => _db.transaction((txn) async {
        final m = p.toMap();
        final int id;
        if (p.id == null) {
          m.remove('id');
          id = await txn.insert('parts', m);
        } else {
          m.remove('created_at');
          await txn.update('parts', m, where: 'id = ?', whereArgs: [p.id]);
          id = p.id!;
        }
        final existing = await txn.query('expenses', columns: ['id'], where: 'part_id = ?', whereArgs: [id]);
        if (p.cost > 0) {
          final e = _partExpense(p, id)..remove('id');
          if (existing.isEmpty) {
            await txn.insert('expenses', e);
          } else {
            e.remove('created_at');
            await txn.update('expenses', e, where: 'id = ?', whereArgs: [existing.first['id']]);
          }
        } else if (existing.isNotEmpty) {
          await txn.delete('expenses', where: 'part_id = ?', whereArgs: [id]);
        }
        return id;
      });

  Future<void> deletePart(int id) => _db.transaction((txn) async {
        await txn.delete('expenses', where: 'part_id = ?', whereArgs: [id]);
        await txn.delete('parts', where: 'id = ?', whereArgs: [id]);
      });

  static Map<String, Object?> _partExpense(Part p, int partId) => Expense(
        date: p.installedDate,
        vehicleId: p.vehicleId,
        category: p.type.expenseCategory,
        amount: p.cost,
        quantity: p.qty == 1 ? null : p.qty,
        odometer: p.installedKm,
        note: p.detail,
        place: p.shop,
        partId: partId,
      ).toMap();

  /// Latest known odometer per vehicle, from fuel entries, trips, visits and fittings.
  Future<Map<int, double>> odometers() async {
    final rows = await _db.rawQuery('''
      SELECT vehicle_id, MAX(km) AS km FROM (
        SELECT vehicle_id, odometer AS km FROM expenses WHERE odometer IS NOT NULL
        UNION ALL SELECT vehicle_id, MAX(COALESCE(start_km, 0), COALESCE(end_km, 0)) FROM trips WHERE start_km IS NOT NULL OR end_km IS NOT NULL
        UNION ALL SELECT vehicle_id, installed_km FROM parts WHERE installed_km IS NOT NULL
        UNION ALL SELECT vehicle_id, odometer FROM service_visits WHERE odometer IS NOT NULL
      ) GROUP BY vehicle_id''');
    return {for (final r in rows) r['vehicle_id'] as int: (r['km'] as num).toDouble()};
  }

  /// The current (latest) fitting of every part, most urgent first.
  Future<List<PartStatus>> partStatuses({int? vehicleId}) async {
    final all = await parts(vehicleId: vehicleId);
    final km = await odometers();
    final latest = <String, Part>{};
    for (final p in all) {
      latest.putIfAbsent(p.slot, () => p); // newest first, so the first wins
    }
    return _byUrgency([for (final p in latest.values) PartStatus(p, currentKm: km[p.vehicleId])]);
  }

  static List<T> _byUrgency<T extends DueStatus>(List<T> items) => items
    ..sort((a, b) {
      final h = a.health.index.compareTo(b.health.index);
      if (h != 0) return h;
      final ad = a.daysLeft ?? 1 << 30, bd = b.daysLeft ?? 1 << 30;
      return ad.compareTo(bd);
    });

  /// Maintenance spend (servicing, parts, oil, tyres, repairs, wash) per month, oldest first.
  Future<List<(DateTime, double)>> maintenanceMonthly({int months = 6, int? vehicleId}) async {
    final now = DateTime.now();
    final points = [for (var i = months - 1; i >= 0; i--) DateTime(now.year, now.month - i, 1)];
    final keys = ExpenseCategory.maintenance.map((c) => "'${c.key}'").join(',');
    final vf = vehicleId == null ? '' : ' AND vehicle_id = $vehicleId';
    final rows = await _db.rawQuery(
        'SELECT substr(date,1,7) AS m, SUM(amount) AS s FROM expenses WHERE category IN ($keys) AND date BETWEEN ? AND ?$vf GROUP BY m',
        [dbDate(points.first), dbDate(DateTime(now.year, now.month + 1, 0))]);
    final byKey = {for (final r in rows) r['m'] as String: (r['s'] as num).toDouble()};
    return [for (final m in points) (m, byKey['${m.year}-${m.month.toString().padLeft(2, '0')}'] ?? 0)];
  }

  // ── Seeding ─────────────────────────────────────────────────────────────

  Future<void> runInTransaction(Future<void> Function(Transaction txn) action) => _db.transaction(action);
}
