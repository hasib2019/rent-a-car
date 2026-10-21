import 'dart:math' as math;

import 'package:flutter/material.dart' show DateUtils;

import '../core/catalog.dart';
import 'models.dart';

/// One fill-up with what it tells about the car.
class FuelFill {
  FuelFill(this.expense);
  final Expense expense;

  /// km per litre / m³ for the stretch this full tank closed, if measurable.
  double? mileage;

  /// km driven on that stretch.
  double? distance;

  /// Taka per km on that stretch.
  double? costPerKm;

  double? get quantity => expense.quantity;
  double? get odometer => expense.odometer;
  DateTime get date => expense.date;

  /// Price per unit: as typed at the pump, else worked out from the bill.
  double? get unitPrice {
    if (expense.unitPrice != null && expense.unitPrice! > 0) return expense.unitPrice;
    final q = expense.quantity;
    return q != null && q > 0 ? expense.amount / q : null;
  }
}

/// A measured stretch between two full tanks.
class FuelSegment {
  const FuelSegment({required this.end, required this.distance, required this.quantity, required this.cost, this.station});
  final DateTime end;
  final double distance;
  final double quantity;
  final double cost;

  /// The pump every litre of this stretch came from; null when it was mixed
  /// or not written down.
  final String? station;

  double get mileage => distance / quantity;
}

/// How far a pump's fuel takes the car, against the car's overall average.
class StationStat {
  StationStat(this.name);
  final String name;
  double distance = 0;
  double quantity = 0;
  int stretches = 0;

  double get mileage => distance / quantity;

  /// Set by [FuelReport.stations]: 0.12 = 12 % fewer km per unit than the
  /// other pumps together.
  double shortfall = 0;

  /// Enough stretches, clearly worse: worth avoiding.
  bool get suspect => stretches >= 2 && shortfall >= 0.08;
}

/// Spend and distance of one calendar month.
class FuelMonth {
  FuelMonth(this.month);
  final DateTime month;
  double cost = 0;
  double quantity = 0;
  double distance = 0;
  int fills = 0;
}

/// Mileage and running cost from a car's fill-ups, by the full-tank method:
/// fill to the brim, and the fuel bought until the next full tank is what the
/// car burnt over the km between them. Partial fills add to the stretch; a
/// missed fill-up (or one without litres) breaks it, and the next full tank
/// starts a new one.
class FuelReport {
  FuelReport._(this.fuel, this.fills, this.segments);

  /// Builds one report per fuel — a bi-fuel CNG/octane car burns both, and
  /// mixing them would make every number meaningless. [fallback] is the
  /// vehicle's own fuel, for fills recorded without one. Most used fuel first.
  static List<FuelReport> byFuel(List<Expense> fills, {FuelType? fallback}) {
    final groups = <FuelType?, List<Expense>>{};
    for (final e in fills) {
      groups.putIfAbsent(e.fuelType ?? fallback, () => []).add(e);
    }
    final reports = [for (final g in groups.entries) FuelReport.build(g.value, fuel: g.key)];
    return reports..sort((a, b) => b.fills.length.compareTo(a.fills.length));
  }

  factory FuelReport.build(List<Expense> raw, {FuelType? fuel}) {
    final fills = [for (final e in _sorted(raw)) FuelFill(e)];
    final segments = <FuelSegment>[];
    double? anchor; // odometer at the last full tank of an unbroken stretch
    var qty = 0.0, cost = 0.0;
    String? station;
    var mixed = false;

    for (final f in fills) {
      final e = f.expense;
      if (e.missed) anchor = null;
      if (anchor != null) {
        if (e.quantity == null || e.quantity! <= 0) {
          anchor = null;
        } else {
          qty += e.quantity!;
          cost += e.amount;
          final pump = _stationKey(e.place);
          if (pump == null || (station != null && _stationKey(station) != pump)) mixed = true;
          station ??= e.place?.trim();
        }
      }
      if (!e.fullTank) continue;
      final odo = e.odometer;
      if (anchor != null && odo != null && odo > anchor && qty > 0) {
        final seg = FuelSegment(end: e.date, distance: odo - anchor, quantity: qty, cost: cost, station: mixed ? null : station);
        segments.add(seg);
        f
          ..mileage = seg.mileage
          ..distance = seg.distance
          ..costPerKm = seg.cost / seg.distance;
      }
      anchor = odo;
      qty = 0;
      cost = 0;
      station = null;
      mixed = false;
    }
    return FuelReport._(fuel, fills, segments);
  }

  /// Pumps typed slightly differently ("Meghna, Banani " / "meghna, banani") are one pump.
  static String? _stationKey(String? place) {
    final k = place?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return k == null || k.isEmpty ? null : k;
  }

  /// Oldest first; on the same day the lower odometer first, new entries last.
  static List<Expense> _sorted(List<Expense> raw) => [...raw]..sort((a, b) {
        final d = a.date.compareTo(b.date);
        if (d != 0) return d;
        if (a.odometer != null && b.odometer != null && a.odometer != b.odometer) return a.odometer!.compareTo(b.odometer!);
        return (a.id ?? 1 << 40).compareTo(b.id ?? 1 << 40);
      });

  final FuelType? fuel;

  /// Oldest first.
  final List<FuelFill> fills;
  final List<FuelSegment> segments;

  bool get isEmpty => fills.isEmpty;

  double get totalCost => fills.fold(0, (a, f) => a + f.expense.amount);
  double get totalQuantity => fills.fold(0, (a, f) => a + (f.quantity ?? 0));

  double get _segDistance => segments.fold(0, (a, s) => a + s.distance);
  double get _segQuantity => segments.fold(0, (a, s) => a + s.quantity);
  double get _segCost => segments.fold(0, (a, s) => a + s.cost);

  /// Overall km per unit across every measured stretch.
  double? get avgMileage => segments.isEmpty ? null : _segDistance / _segQuantity;
  double? get lastMileage => segments.isEmpty ? null : segments.last.mileage;
  double? get bestMileage => segments.isEmpty ? null : segments.map((s) => s.mileage).reduce(math.max);
  double? get worstMileage => segments.isEmpty ? null : segments.map((s) => s.mileage).reduce(math.min);

  /// Fuel taka per km driven.
  double? get costPerKm => segments.isEmpty ? null : _segCost / _segDistance;

  /// Average pump price over every fill that knows its quantity.
  double? get avgUnitPrice {
    var q = 0.0, c = 0.0;
    for (final f in fills) {
      if (f.quantity != null && f.quantity! > 0) {
        q += f.quantity!;
        c += f.expense.amount;
      }
    }
    return q > 0 ? c / q : null;
  }

  double? get lastUnitPrice {
    for (final f in fills.reversed) {
      if (f.unitPrice != null) return f.unitPrice;
    }
    return null;
  }

  double? get lastOdometer {
    double? best;
    for (final f in fills) {
      if (f.odometer != null && (best == null || f.odometer! > best)) best = f.odometer;
    }
    return best;
  }

  /// km covered by the odometer readings in the log.
  double? get trackedDistance {
    final odos = [for (final f in fills) if (f.odometer != null) f.odometer!];
    if (odos.length < 2) return null;
    return odos.reduce(math.max) - odos.reduce(math.min);
  }

  DateTime? get lastFill => fills.isEmpty ? null : fills.last.date;

  /// Average days from one fill-up to the next.
  double? get avgDaysBetween {
    if (fills.length < 2) return null;
    return fills.last.date.difference(fills.first.date).inDays / (fills.length - 1);
  }

  int? daysSinceLastFill([DateTime? today]) =>
      lastFill == null ? null : DateUtils.dateOnly(today ?? DateTime.now()).difference(lastFill!).inDays;

  /// How much worse the latest stretch was than the ones before it (0.2 =
  /// 20 % fewer km per unit). Null until there are three stretches to compare.
  double? get mileageDrop {
    if (segments.length < 3) return null;
    final before = segments.sublist(0, segments.length - 1);
    final base = before.fold<double>(0, (a, s) => a + s.distance) / before.fold<double>(0, (a, s) => a + s.quantity);
    return 1 - segments.last.mileage / base;
  }

  /// The latest stretch is clearly worse — worth a look at tyres, filters or the engine.
  bool get mileageAlert => (mileageDrop ?? 0) >= 0.15;

  /// No fill-up for much longer than usual (or a month, for a short log).
  bool overdueLog([DateTime? today]) {
    final since = daysSinceLastFill(today);
    if (since == null) return false;
    final usual = avgDaysBetween;
    return since > (usual == null ? 30 : math.max(10, usual * 2.5));
  }

  /// Spend and distance per month for the last [count] months, oldest first.
  /// A stretch's km land in the month its closing full tank was filled.
  List<FuelMonth> months({int count = 6, DateTime? until}) {
    final end = until ?? DateTime.now();
    final out = [for (var i = count - 1; i >= 0; i--) FuelMonth(DateTime(end.year, end.month - i))];
    FuelMonth? of(DateTime d) {
      for (final m in out) {
        if (m.month.year == d.year && m.month.month == d.month) return m;
      }
      return null;
    }

    for (final f in fills) {
      final m = of(f.date);
      if (m == null) continue;
      m
        ..cost += f.expense.amount
        ..quantity += f.quantity ?? 0
        ..fills += 1;
    }
    for (final s in segments) {
      of(s.end)?.distance += s.distance;
    }
    return out;
  }

  /// Mileage per pump, worst first. Only stretches filled entirely at one
  /// pump count, so a short-measuring pump shows up as fewer km per litre.
  List<StationStat> stations() {
    final avg = avgMileage;
    final out = <String, StationStat>{};
    for (final s in segments) {
      final key = _stationKey(s.station);
      if (key == null) continue;
      out.putIfAbsent(key, () => StationStat(s.station!))
        ..distance += s.distance
        ..quantity += s.quantity
        ..stretches += 1;
    }
    final list = out.values.toList();
    // Each pump against the others: its own short litres must not pull the
    // yardstick down with it.
    final dist = list.fold<double>(0, (a, x) => a + x.distance), qty = list.fold<double>(0, (a, x) => a + x.quantity);
    for (final st in list) {
      final otherQty = qty - st.quantity;
      final base = otherQty > 0 ? (dist - st.distance) / otherQty : avg;
      if (base != null) st.shortfall = 1 - st.mileage / base;
    }
    return list..sort((a, b) => a.mileage.compareTo(b.mileage));
  }

  /// What the mileage would be if [candidate] were saved (live preview in the form).
  double? previewMileage(Expense candidate) {
    final others = [for (final f in fills) if (f.expense.id == null || f.expense.id != candidate.id) f.expense];
    final report = FuelReport.build([...others, candidate], fuel: fuel);
    for (final f in report.fills) {
      if (identical(f.expense, candidate)) return f.mileage;
    }
    return null;
  }
}

/// What a car that burns two fuels saved by running on the cheaper one: every
/// km measured on it, priced at the difference in fuel cost per km.
class FuelSavings {
  const FuelSavings._({required this.cheap, required this.dear, required this.distance, required this.saved, required this.since});

  /// Cheapest and dearest fuel per km (CNG and octane, usually).
  final FuelReport cheap;
  final FuelReport dear;

  /// km measured on the cheap fuel, and the taka that saved.
  final double distance;
  final double saved;

  /// First fill of the cheap fuel: when the saving started.
  final DateTime since;

  double get cheapPerKm => cheap.costPerKm!;
  double get dearPerKm => dear.costPerKm!;

  /// Null unless two fuels each have a measured cost per km.
  static FuelSavings? of(List<FuelReport> reports, {DateTime? from}) {
    final measured = reports.where((r) => r.costPerKm != null).toList()..sort((a, b) => a.costPerKm!.compareTo(b.costPerKm!));
    if (measured.length < 2) return null;
    final cheap = measured.first, dear = measured.last;
    final perKm = dear.costPerKm! - cheap.costPerKm!;
    if (perKm <= 0) return null;
    final distance = cheap.segments.where((s) => from == null || !s.end.isBefore(from)).fold<double>(0, (a, s) => a + s.distance);
    return FuelSavings._(cheap: cheap, dear: dear, distance: distance, saved: distance * perKm, since: cheap.fills.first.date);
  }

  /// Saving per day since the cheap fuel came in.
  double savedPerDay([DateTime? today]) {
    final days = DateUtils.dateOnly(today ?? DateTime.now()).difference(since).inDays;
    return days <= 0 ? 0 : saved / days;
  }

  /// When the saving will have paid back [cost] at today's pace (null if it
  /// already has, or there is no pace yet).
  DateTime? paybackDate(double cost, [DateTime? today]) {
    final now = DateUtils.dateOnly(today ?? DateTime.now());
    if (saved >= cost) return null;
    final perDay = savedPerDay(now);
    if (perDay <= 0) return null;
    return now.add(Duration(days: ((cost - saved) / perDay).ceil()));
  }
}
