import '../core/catalog.dart';
import '../core/format.dart';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _dn(Object? v) => (v as num?)?.toDouble();
String _now() => DateTime.now().toIso8601String();

class Driver {
  Driver({
    this.id,
    required this.name,
    this.phone,
    this.nid,
    this.licenseNo,
    this.address,
    this.joinDate,
    this.openingDue = 0,
    this.active = true,
    this.note,
  });

  final int? id;
  final String name;
  final String? phone;
  final String? nid;
  final String? licenseNo;
  final String? address;
  final DateTime? joinDate;
  final double openingDue;
  final bool active;
  final String? note;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = String.fromCharCodes(parts.first.runes.take(1));
    if (parts.length == 1) return first;
    return first + String.fromCharCodes(parts.last.runes.take(1));
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name.trim(),
        'phone': phone,
        'nid': nid,
        'license_no': licenseNo,
        'address': address,
        'join_date': joinDate == null ? null : dbDate(joinDate!),
        'opening_due': openingDue,
        'active': active ? 1 : 0,
        'note': note,
        'created_at': _now(),
      };

  factory Driver.fromMap(Map<String, Object?> m) => Driver(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        nid: m['nid'] as String?,
        licenseNo: m['license_no'] as String?,
        address: m['address'] as String?,
        joinDate: m['join_date'] == null ? null : parseDbDate(m['join_date'] as String),
        openingDue: _d(m['opening_due']),
        active: (m['active'] as int? ?? 1) == 1,
        note: m['note'] as String?,
      );
}

class Vehicle {
  Vehicle({
    this.id,
    required this.name,
    required this.type,
    this.regNo,
    this.model,
    this.purchasePrice = 0,
    this.purchaseDate,
    this.dailyTarget = 0,
    this.driverId,
    this.status = VehicleStatus.active,
    this.note,
  });

  final int? id;
  final String name;
  final VehicleType type;
  final String? regNo;
  final String? model;
  final double purchasePrice;
  final DateTime? purchaseDate;
  final double dailyTarget;
  final int? driverId;
  final VehicleStatus status;
  final String? note;

  bool get isActive => status == VehicleStatus.active;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name.trim(),
        'type': type.key,
        'reg_no': regNo,
        'model': model,
        'purchase_price': purchasePrice,
        'purchase_date': purchaseDate == null ? null : dbDate(purchaseDate!),
        'daily_target': dailyTarget,
        'driver_id': driverId,
        'status': status.key,
        'note': note,
        'created_at': _now(),
      };

  factory Vehicle.fromMap(Map<String, Object?> m) => Vehicle(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: VehicleType.from(m['type'] as String?),
        regNo: m['reg_no'] as String?,
        model: m['model'] as String?,
        purchasePrice: _d(m['purchase_price']),
        purchaseDate: m['purchase_date'] == null ? null : parseDbDate(m['purchase_date'] as String),
        dailyTarget: _d(m['daily_target']),
        driverId: m['driver_id'] as int?,
        status: VehicleStatus.from(m['status'] as String?),
        note: m['note'] as String?,
      );
}

class Income {
  Income({
    this.id,
    required this.date,
    required this.vehicleId,
    this.driverId,
    required this.kind,
    this.target = 0,
    required this.amount,
    this.note,
  });

  final int? id;
  final DateTime date;
  final int vehicleId;
  final int? driverId;
  final IncomeKind kind;
  final double target;
  final double amount;
  final String? note;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': dbDate(date),
        'vehicle_id': vehicleId,
        'driver_id': driverId,
        'kind': kind.key,
        'target': target,
        'amount': amount,
        'note': note,
        'created_at': _now(),
      };

  factory Income.fromMap(Map<String, Object?> m) => Income(
        id: m['id'] as int?,
        date: parseDbDate(m['date'] as String),
        vehicleId: m['vehicle_id'] as int,
        driverId: m['driver_id'] as int?,
        kind: IncomeKind.from(m['kind'] as String?),
        target: _d(m['target']),
        amount: _d(m['amount']),
        note: m['note'] as String?,
      );
}

class Expense {
  Expense({
    this.id,
    required this.date,
    required this.vehicleId,
    required this.category,
    required this.amount,
    this.quantity,
    this.odometer,
    this.note,
  });

  final int? id;
  final DateTime date;
  final int vehicleId;
  final ExpenseCategory category;
  final double amount;
  final double? quantity;
  final double? odometer;
  final String? note;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': dbDate(date),
        'vehicle_id': vehicleId,
        'category': category.key,
        'amount': amount,
        'quantity': quantity,
        'odometer': odometer,
        'note': note,
        'created_at': _now(),
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?,
        date: parseDbDate(m['date'] as String),
        vehicleId: m['vehicle_id'] as int,
        category: ExpenseCategory.from(m['category'] as String?),
        amount: _d(m['amount']),
        quantity: _dn(m['quantity']),
        odometer: _dn(m['odometer']),
        note: m['note'] as String?,
      );
}

class Paper {
  Paper({this.id, required this.vehicleId, required this.type, required this.expiry, this.note});

  final int? id;
  final int vehicleId;
  final PaperType type;
  final DateTime expiry;
  final String? note;

  int get daysLeft => expiry.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'type': type.key,
        'expiry_date': dbDate(expiry),
        'note': note,
      };

  factory Paper.fromMap(Map<String, Object?> m) => Paper(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        type: PaperType.from(m['type'] as String?),
        expiry: parseDbDate(m['expiry_date'] as String),
        note: m['note'] as String?,
      );
}

/// A single row in the combined ledger (income or expense).
class LedgerEntry {
  LedgerEntry({
    required this.isIncome,
    required this.id,
    required this.date,
    required this.vehicleId,
    required this.driverId,
    required this.category,
    required this.amount,
    required this.target,
    required this.quantity,
    required this.note,
  });

  final bool isIncome;
  final int id;
  final DateTime date;
  final int vehicleId;
  final int? driverId;
  final String category;
  final double amount;
  final double target;
  final double? quantity;
  final String? note;

  IncomeKind get incomeKind => IncomeKind.from(category);
  ExpenseCategory get expenseCategory => ExpenseCategory.from(category);

  factory LedgerEntry.fromMap(Map<String, Object?> m) => LedgerEntry(
        isIncome: m['src'] == 'i',
        id: m['id'] as int,
        date: parseDbDate(m['date'] as String),
        vehicleId: m['vehicle_id'] as int,
        driverId: m['driver_id'] as int?,
        category: m['cat'] as String,
        amount: _d(m['amount']),
        target: _d(m['target']),
        quantity: _dn(m['quantity']),
        note: m['note'] as String?,
      );
}

class Totals {
  const Totals({this.income = 0, this.expense = 0});
  final double income;
  final double expense;
  double get profit => income - expense;
  double get margin => income <= 0 ? 0 : profit / income;
}

class VehicleStat {
  VehicleStat({
    required this.vehicleId,
    this.income = 0,
    this.expense = 0,
    this.fuel = 0,
    this.maintenance = 0,
    this.activeDays = 0,
  });

  final int vehicleId;
  double income;
  double expense;
  double fuel;
  double maintenance;
  int activeDays;
  double get profit => income - expense;
}

class MonthPoint {
  MonthPoint(this.month, {this.income = 0, this.expense = 0});
  final DateTime month;
  double income;
  double expense;
  double get profit => income - expense;
}

/// One day of a driver's collection record (for the heat-map).
class DayRecord {
  DayRecord({this.target = 0, this.amount = 0, this.off = false});
  double target;
  double amount;
  bool off;
}

class Period {
  const Period(this.from, this.to);
  final DateTime from;
  final DateTime to;

  static Period thisMonth() {
    final n = DateTime.now();
    return Period(DateTime(n.year, n.month, 1), DateTime(n.year, n.month + 1, 0));
  }

  static Period lastMonth() {
    final n = DateTime.now();
    return Period(DateTime(n.year, n.month - 1, 1), DateTime(n.year, n.month, 0));
  }

  static Period month(DateTime m) => Period(DateTime(m.year, m.month, 1), DateTime(m.year, m.month + 1, 0));

  static Period thisYear() {
    final n = DateTime.now();
    return Period(DateTime(n.year, 1, 1), DateTime(n.year, 12, 31));
  }

  static Period allTime() => Period(DateTime(2000), DateTime(2100));

  static Period day(DateTime d) => Period(d, d);

  int get lengthInDays => to.difference(from).inDays + 1;
}
