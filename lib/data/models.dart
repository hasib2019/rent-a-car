import 'package:flutter/material.dart' show DateUtils;

import '../core/catalog.dart';
import '../core/format.dart';
import '../core/l10n.dart';

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
    this.licenseExpiry,
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
  final DateTime? licenseExpiry;

  /// Days until the driving licence expires (negative when expired).
  int? get licenseDaysLeft => licenseExpiry?.difference(DateUtils.dateOnly(DateTime.now())).inDays;

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
        'license_expiry': licenseExpiry == null ? null : dbDate(licenseExpiry!),
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
        licenseExpiry: m['license_expiry'] == null ? null : parseDbDate(m['license_expiry'] as String),
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
    this.chassisNo,
    this.engineNo,
    this.color,
    this.year,
    this.fuel,
    this.capacity,
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
  final String? chassisNo;
  final String? engineNo;
  final String? color;

  /// Model / manufacture year.
  final int? year;
  final FuelType? fuel;

  /// Seats or load, as the owner writes it ("৪ সিট", "১.৫ টন").
  final String? capacity;

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
        'chassis_no': chassisNo,
        'engine_no': engineNo,
        'color': color,
        'year': year,
        'fuel': fuel?.key,
        'capacity': capacity,
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
        chassisNo: m['chassis_no'] as String?,
        engineNo: m['engine_no'] as String?,
        color: m['color'] as String?,
        year: m['year'] as int?,
        fuel: FuelType.from(m['fuel'] as String?),
        capacity: m['capacity'] as String?,
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
    this.tripId,
  });

  final int? id;
  final DateTime date;
  final int vehicleId;
  final int? driverId;
  final IncomeKind kind;
  final double target;
  final double amount;
  final String? note;

  /// Set when this is the fare of a [Trip].
  final int? tripId;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': dbDate(date),
        'vehicle_id': vehicleId,
        'driver_id': driverId,
        'kind': kind.key,
        'target': target,
        'amount': amount,
        'note': note,
        'trip_id': tripId,
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
        tripId: m['trip_id'] as int?,
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
    this.place,
    this.tripId,
    this.partId,
    this.visitId,
  });

  final int? id;
  final DateTime date;
  final int vehicleId;
  final ExpenseCategory category;
  final double amount;
  final double? quantity;
  final double? odometer;
  final String? note;

  /// Where on the road the money was spent (trip costs).
  final String? place;

  /// Set when this is a cost of a [Trip].
  final int? tripId;

  /// Set when this is the fitting cost of a [Part].
  final int? partId;

  /// Set when this is the labour bill of a [ServiceVisit].
  final int? visitId;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': dbDate(date),
        'vehicle_id': vehicleId,
        'category': category.key,
        'amount': amount,
        'quantity': quantity,
        'odometer': odometer,
        'note': note,
        'place': place,
        'trip_id': tripId,
        'part_id': partId,
        'visit_id': visitId,
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
        place: m['place'] as String?,
        tripId: m['trip_id'] as int?,
        partId: m['part_id'] as int?,
        visitId: m['visit_id'] as int?,
      );
}

class Paper {
  Paper({this.id, required this.vehicleId, required this.type, required this.expiry, this.note, this.docNo, this.provider});

  final int? id;
  final int vehicleId;
  final PaperType type;
  final DateTime expiry;
  final String? note;

  /// Certificate / policy / token number.
  final String? docNo;

  /// Issuing office or insurance company.
  final String? provider;

  int get daysLeft => expiry.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'type': type.key,
        'expiry_date': dbDate(expiry),
        'note': note,
        'doc_no': docNo,
        'provider': provider,
      };

  factory Paper.fromMap(Map<String, Object?> m) => Paper(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        type: PaperType.from(m['type'] as String?),
        expiry: parseDbDate(m['expiry_date'] as String),
        note: m['note'] as String?,
        docNo: m['doc_no'] as String?,
        provider: m['provider'] as String?,
      );
}

/// A hire or goods trip: where the vehicle went and what the client paid.
/// The fare is mirrored into `incomes` and road costs live in `expenses`
/// (both linked by `trip_id`), so every report counts them automatically.
class Trip {
  Trip({
    this.id,
    required this.vehicleId,
    this.driverId,
    required this.startDate,
    this.endDate,
    required this.origin,
    required this.destination,
    this.client,
    this.fare = 0,
    this.startKm,
    this.endKm,
    this.note,
    this.clientPhone,
    this.status = TripStatus.done,
    this.goods,
    this.challanNo,
  });

  final int? id;
  final int vehicleId;
  final int? driverId;
  final DateTime startDate;
  final DateTime? endDate;
  final String origin;
  final String destination;
  final String? client;

  /// Agreed fare. What the party has paid so far lives in [TripPayment]s.
  final double fare;
  final double? startKm;
  final double? endKm;
  final String? note;
  final String? clientPhone;
  final TripStatus status;

  /// Cargo or passengers ("২০০ বস্তা সিমেন্ট", "৪ জন যাত্রী").
  final String? goods;

  /// Challan / invoice / booking number.
  final String? challanNo;

  /// The fare that counts as earned (nothing for a cancelled trip).
  double get earned => status.countsFare ? fare : 0;

  String get route => '${origin.trim()} → ${destination.trim()}';

  double? get distance => startKm != null && endKm != null && endKm! > startKm! ? endKm! - startKm! : null;

  int get days => endDate == null ? 1 : endDate!.difference(startDate).inDays + 1;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'driver_id': driverId,
        'start_date': dbDate(startDate),
        'end_date': endDate == null ? null : dbDate(endDate!),
        'origin': origin.trim(),
        'destination': destination.trim(),
        'client': client,
        'fare': fare,
        'start_km': startKm,
        'end_km': endKm,
        'note': note,
        'client_phone': clientPhone,
        'status': status.key,
        'goods': goods,
        'challan_no': challanNo,
        'created_at': _now(),
      };

  factory Trip.fromMap(Map<String, Object?> m) => Trip(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        driverId: m['driver_id'] as int?,
        startDate: parseDbDate(m['start_date'] as String),
        endDate: m['end_date'] == null ? null : parseDbDate(m['end_date'] as String),
        origin: m['origin'] as String,
        destination: m['destination'] as String,
        client: m['client'] as String?,
        fare: _d(m['fare']),
        startKm: _dn(m['start_km']),
        endKm: _dn(m['end_km']),
        note: m['note'] as String?,
        clientPhone: m['client_phone'] as String?,
        status: TripStatus.from(m['status'] as String?),
        goods: m['goods'] as String?,
        challanNo: m['challan_no'] as String?,
      );
}

/// Money a party paid against a trip (advance or later instalments).
class TripPayment {
  TripPayment({this.id, this.tripId, required this.date, required this.amount, this.method = PayMethod.cash, this.note});

  final int? id;
  final int? tripId;
  final DateTime date;
  final double amount;
  final PayMethod method;
  final String? note;

  Map<String, Object?> toMap() => {
        'id': id,
        'trip_id': tripId,
        'date': dbDate(date),
        'amount': amount,
        'method': method.key,
        'note': note,
        'created_at': _now(),
      };

  factory TripPayment.fromMap(Map<String, Object?> m) => TripPayment(
        id: m['id'] as int?,
        tripId: m['trip_id'] as int?,
        date: parseDbDate(m['date'] as String),
        amount: _d(m['amount']),
        method: PayMethod.from(m['method'] as String?),
        note: m['note'] as String?,
      );
}

/// A trip with its summed road costs and payments, for lists.
class TripSummary {
  TripSummary(this.trip, {this.cost = 0, this.fuel = 0, this.received = 0});
  final Trip trip;
  final double cost;
  final double fuel;

  /// Paid by the party so far.
  final double received;
  double get profit => trip.earned - cost;

  /// What the party still owes.
  double get due => trip.status.countsFare ? trip.fare - received : 0;
}

/// Every trip done for one client, grouped by name.
class PartySummary {
  PartySummary({required this.name, this.phone, this.trips = 0, this.fare = 0, this.received = 0, this.lastTrip});

  /// As written on the most recent trip.
  String name;
  String? phone;
  int trips;
  double fare;
  double received;
  DateTime? lastTrip;
  double get due => fare - received;

  /// Clients are matched by name, ignoring case and extra spaces.
  static String keyOf(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// One trip to a garage or service centre: the job card.
class ServiceVisit {
  ServiceVisit({
    this.id,
    required this.vehicleId,
    required this.date,
    this.odometer,
    this.kind = ServiceKind.local,
    this.workshop,
    this.mechanic,
    this.jobNo,
    this.title,
    this.labour = 0,
    this.nextDate,
    this.nextKm,
    this.note,
  });

  final int? id;
  final int vehicleId;
  final DateTime date;
  final double? odometer;
  final ServiceKind kind;

  /// Garage or service centre name.
  final String? workshop;

  /// Mechanic / service advisor (name or phone).
  final String? mechanic;

  /// Job card or bill number.
  final String? jobNo;

  /// What was done ("১০,০০০ কিমি সার্ভিস", "২য় ফ্রি সার্ভিস").
  final String? title;

  /// Mechanic / service charge, excluding parts.
  final double labour;

  /// When the next general service is due.
  final DateTime? nextDate;
  final double? nextKm;
  final String? note;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'date': dbDate(date),
        'odometer': odometer,
        'kind': kind.key,
        'workshop': workshop,
        'mechanic': mechanic,
        'job_no': jobNo,
        'title': title,
        'labour': labour,
        'next_date': nextDate == null ? null : dbDate(nextDate!),
        'next_km': nextKm,
        'note': note,
        'created_at': _now(),
      };

  factory ServiceVisit.fromMap(Map<String, Object?> m) => ServiceVisit(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        date: parseDbDate(m['date'] as String),
        odometer: _dn(m['odometer']),
        kind: ServiceKind.from(m['kind'] as String?),
        workshop: m['workshop'] as String?,
        mechanic: m['mechanic'] as String?,
        jobNo: m['job_no'] as String?,
        title: m['title'] as String?,
        labour: _d(m['labour']),
        nextDate: m['next_date'] == null ? null : parseDbDate(m['next_date'] as String),
        nextKm: _dn(m['next_km']),
        note: m['note'] as String?,
      );
}

/// A visit with its parts bill, for lists.
class VisitSummary {
  VisitSummary(this.visit, {this.partsCost = 0, this.partsCount = 0});
  final ServiceVisit visit;
  final double partsCost;
  final int partsCount;
  double get total => visit.labour + partsCost;
}

/// One fitting of a wear part (oil, filter, tyre…) and when it is due again.
class Part {
  Part({
    this.id,
    required this.vehicleId,
    required this.type,
    this.detail,
    required this.installedDate,
    this.installedKm,
    this.cost = 0,
    this.nextDate,
    this.nextKm,
    this.note,
    this.visitId,
    this.shop,
    this.qty = 1,
    this.warrantyUntil,
  });

  final int? id;
  final int vehicleId;
  final PartType type;

  /// Brand / grade, or the part's name when [type] is [PartType.other].
  final String? detail;
  final DateTime installedDate;
  final double? installedKm;

  /// Total price paid for [qty] pieces.
  final double cost;
  final DateTime? nextDate;
  final double? nextKm;
  final String? note;

  /// The garage visit this was fitted in, if any.
  final int? visitId;

  /// Shop the part was bought from.
  final String? shop;
  final double qty;
  final DateTime? warrantyUntil;

  double get unitPrice => qty <= 0 ? cost : cost / qty;

  /// Days of warranty left (negative once it has run out).
  int? get warrantyDaysLeft => warrantyUntil?.difference(DateUtils.dateOnly(DateTime.now())).inDays;

  bool get _hasDetail => detail != null && detail!.trim().isNotEmpty;

  /// Short name shown in lists.
  String label(S s) => type == PartType.other && _hasDetail ? detail!.trim() : type.label(s);

  /// Brand/grade line, when it is not already the label.
  String? get subLabel => type != PartType.other && _hasDetail ? detail!.trim() : null;

  /// Fittings of the same part on the same vehicle replace each other.
  String get slot => '$vehicleId|${type.key}|${type == PartType.other ? (detail ?? '').trim().toLowerCase() : ''}';

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'type': type.key,
        'detail': _hasDetail ? detail!.trim() : null,
        'installed_date': dbDate(installedDate),
        'installed_km': installedKm,
        'cost': cost,
        'next_date': nextDate == null ? null : dbDate(nextDate!),
        'next_km': nextKm,
        'note': note,
        'visit_id': visitId,
        'shop': shop,
        'qty': qty,
        'warranty_until': warrantyUntil == null ? null : dbDate(warrantyUntil!),
        'created_at': _now(),
      };

  factory Part.fromMap(Map<String, Object?> m) => Part(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        type: PartType.from(m['type'] as String?),
        detail: m['detail'] as String?,
        installedDate: parseDbDate(m['installed_date'] as String),
        installedKm: _dn(m['installed_km']),
        cost: _d(m['cost']),
        nextDate: m['next_date'] == null ? null : parseDbDate(m['next_date'] as String),
        nextKm: _dn(m['next_km']),
        note: m['note'] as String?,
        visitId: m['visit_id'] as int?,
        shop: m['shop'] as String?,
        qty: _dn(m['qty']) ?? 1,
        warrantyUntil: m['warranty_until'] == null ? null : parseDbDate(m['warranty_until'] as String),
      );
}

enum DueHealth { overdue, soon, ok, unscheduled }

/// Something due again by a date and/or an odometer reading, whichever comes
/// first: a part's next change or a vehicle's next service.
abstract class DueStatus {
  DueStatus({this.currentKm, DateTime? today}) : _today = DateUtils.dateOnly(today ?? DateTime.now());

  /// Within this many days or km of the due point counts as "soon".
  static const soonDays = 15;
  static const soonKm = 500;

  /// Latest odometer reading known for the vehicle.
  final double? currentKm;
  final DateTime _today;

  int get vehicleId;
  DateTime? get nextDate;
  double? get nextKm;

  int? get daysLeft => nextDate?.difference(_today).inDays;

  double? get kmLeft => nextKm == null || currentKm == null ? null : nextKm! - currentKm!;

  DueHealth get health {
    final d = daysLeft, k = kmLeft;
    if (d == null && k == null) return DueHealth.unscheduled;
    if ((d != null && d < 0) || (k != null && k < 0)) return DueHealth.overdue;
    if ((d != null && d <= soonDays) || (k != null && k <= soonKm)) return DueHealth.soon;
    return DueHealth.ok;
  }

  bool get needsAttention => health == DueHealth.overdue || health == DueHealth.soon;

  /// Whether the km limit is the more pressing one (drives the status label).
  bool get kmIsCloser {
    final d = daysLeft, k = kmLeft;
    if (k == null) return false;
    if (d == null) return true;
    // Compare as fractions of the "soon" window so days and km are comparable.
    return k / soonKm < d / soonDays;
  }
}

/// The latest fitting of a part, with how close it is to its next change.
class PartStatus extends DueStatus {
  PartStatus(this.part, {super.currentKm, super.today});
  final Part part;

  @override
  int get vehicleId => part.vehicleId;
  @override
  DateTime? get nextDate => part.nextDate;
  @override
  double? get nextKm => part.nextKm;
}

/// A vehicle's next general service, from its latest scheduled visit.
class ServiceStatus extends DueStatus {
  ServiceStatus(this.visit, {super.currentKm, super.today});
  final ServiceVisit visit;

  @override
  int get vehicleId => visit.vehicleId;
  @override
  DateTime? get nextDate => visit.nextDate;
  @override
  double? get nextKm => visit.nextKm;
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
    this.place,
    this.tripId,
    this.route,
    this.partId,
    this.partType,
    this.visitId,
    this.workshop,
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
  final String? place;
  final int? tripId;

  /// "Origin → Destination" of the linked trip.
  final String? route;
  final int? partId;
  final PartType? partType;

  /// The garage visit this cost belongs to (its labour, or a part fitted there).
  final int? visitId;
  final String? workshop;

  /// Rows owned by a trip, part or visit are edited there, not in the entry pad.
  bool get isLinked => tripId != null || partId != null || visitId != null;

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
        place: m['place'] as String?,
        tripId: m['trip_id'] as int?,
        route: m['route'] as String?,
        partId: m['part_id'] as int?,
        partType: m['part_type'] == null ? null : PartType.from(m['part_type'] as String),
        visitId: m['visit_id'] as int?,
        workshop: m['workshop'] as String?,
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
