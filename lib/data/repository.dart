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
  static const schemaVersion = 1;

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
          onCreate: (db, _) => _createSchema(db),
        ),
      );

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
      for (final t in ['papers', 'expenses', 'incomes', 'vehicles', 'drivers']) {
        await txn.delete(t);
      }
      await txn.execute("DELETE FROM sqlite_sequence");
    });
  }

  Future<Map<String, int>> counts() async {
    final out = <String, int>{};
    for (final t in ['vehicles', 'drivers', 'incomes', 'expenses', 'papers']) {
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
    if (incomeOnly != false) {
      parts.add("SELECT 'i' AS src, id, date, vehicle_id, driver_id, kind AS cat, amount, target, NULL AS quantity, note, created_at FROM incomes WHERE ${iWhere.join(' AND ')}");
      args.addAll(iArgs);
    }
    if (incomeOnly != true && driverId == null) {
      parts.add("SELECT 'e' AS src, id, date, vehicle_id, NULL AS driver_id, category AS cat, amount, 0 AS target, quantity, note, created_at FROM expenses WHERE ${eWhere.join(' AND ')}");
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

  // ── Seeding ─────────────────────────────────────────────────────────────

  Future<void> runInTransaction(Future<void> Function(Transaction txn) action) => _db.transaction(action);
}
