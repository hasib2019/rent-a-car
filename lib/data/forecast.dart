import 'dart:math' as math;

import 'package:flutter/material.dart' show DateUtils;

import '../core/catalog.dart';
import 'models.dart';

enum ForecastKind { paper, service, part, fuel, regular }

/// One cost expected on a day: a renewal, a service, a part, or a month's
/// running costs. [amount] is null when nothing on record says what it costs.
class ForecastItem {
  const ForecastItem({required this.date, required this.kind, this.amount, this.paper, this.part, this.overdue = false});
  final DateTime date;
  final ForecastKind kind;
  final double? amount;
  final PaperType? paper;
  final PartType? part;

  /// Already due — counted in the current month.
  final bool overdue;

  /// Renewals, services and parts; fuel and regular costs are monthly averages.
  bool get oneOff => kind == ForecastKind.paper || kind == ForecastKind.service || kind == ForecastKind.part;
}

class ForecastMonth {
  ForecastMonth(this.month);
  final DateTime month;
  final List<ForecastItem> items = [];

  double get total => items.fold(0, (a, i) => a + (i.amount ?? 0));
  double get oneOffTotal => items.where((i) => i.oneOff).fold(0, (a, i) => a + (i.amount ?? 0));
}

/// The next twelve months of a car's costs, from what the books already know:
/// paper expiry dates and their renewal fees, service and part schedules
/// (km turned into dates by how far the car goes a day), and the recent
/// average of fuel and everyday costs.
class CostForecast {
  CostForecast._(this.months, this.kmPerDay);

  final List<ForecastMonth> months;

  /// How far the car goes on an average day, if the odometer says.
  final double? kmPerDay;

  double get total => months.fold(0, (a, m) => a + m.total);
  double get perMonth => months.isEmpty ? 0 : total / months.length;

  /// Renewals, services and parts in date order.
  List<ForecastItem> get oneOffs => [for (final m in months) ...m.items.where((i) => i.oneOff)]..sort((a, b) => a.date.compareTo(b.date));

  /// Expected costs whose amount is unknown (a paper without a renewal fee).
  int get unknown => oneOffs.where((i) => i.amount == null).length;

  /// The month with the most one-off costs, to warn about ahead of time.
  ForecastMonth? get heaviest {
    final withCosts = months.where((m) => m.oneOffTotal > 0).toList();
    if (withCosts.isEmpty) return null;
    return withCosts.reduce((a, b) => b.oneOffTotal > a.oneOffTotal ? b : a);
  }

  static CostForecast build({
    required DateTime today,
    required List<Paper> papers,
    required List<ServiceStatus> services,
    required List<VisitSummary> visits,
    required List<PartStatus> parts,
    required List<Expense> fills,
    required double fuelLast90,
    required double regularLast90,
    double? currentKm,
    int count = 12,
  }) {
    final now = DateUtils.dateOnly(today);
    final months = [for (var i = 0; i < count; i++) ForecastMonth(DateTime(now.year, now.month + i))];
    final end = DateTime(now.year, now.month + count, 0);
    final kmPerDay = _kmPerDay(fills, now);

    void add(ForecastItem item) {
      final d = item.date.isBefore(now) ? now : item.date;
      for (final m in months) {
        if (m.month.year == d.year && m.month.month == d.month) {
          m.items.add(item);
          return;
        }
      }
    }

    /// Due date of a km/date schedule: whichever comes first.
    DateTime? due(DateTime? date, double? km) {
      DateTime? byKm;
      if (km != null && currentKm != null && kmPerDay != null && kmPerDay > 0) {
        byKm = now.add(Duration(days: math.max(0, ((km - currentKm) / kmPerDay).round())));
      } else if (km != null && currentKm != null && km <= currentKm) {
        byKm = now;
      }
      if (date == null) return byKm;
      if (byKm == null) return date;
      return date.isBefore(byKm) ? date : byKm;
    }

    /// Days between repeats of a schedule set [days] / [km] apart.
    int? every(int? days, double? km) {
      final byKm = km != null && km > 0 && kmPerDay != null && kmPerDay > 0 ? (km / kmPerDay).round() : null;
      final all = [?days, ?byKm].where((d) => d > 0);
      return all.isEmpty ? null : all.reduce(math.min);
    }

    void schedule(DateTime? first, int? gap, ForecastItem Function(DateTime d, bool overdue) make, {bool late = false}) {
      if (first == null) return;
      var d = first;
      for (var i = 0; i < 24 && !d.isAfter(end); i++) {
        add(make(d, d.isBefore(now) || (i == 0 && late)));
        if (gap == null) return;
        d = (d.isBefore(now) ? now : d).add(Duration(days: gap));
      }
    }

    // Papers: renew on expiry (a lapsed one is due now), then yearly.
    for (final p in papers) {
      schedule(p.expiry, 365, (d, late) => ForecastItem(date: d, kind: ForecastKind.paper, amount: p.renewalCost, paper: p.type, overdue: late));
    }

    // General service: the next one from the latest visit, then at the same interval.
    final pastServices = visits.map((v) => v.total).where((c) => c > 0).toList();
    final serviceCost = pastServices.isEmpty ? null : pastServices.reduce((a, b) => a + b) / pastServices.length;
    for (final st in services) {
      final v = st.visit;
      final gapDays = v.nextDate?.difference(v.date).inDays;
      final gapKm = v.nextKm != null && v.odometer != null ? v.nextKm! - v.odometer! : null;
      schedule(due(v.nextDate, v.nextKm), every(gapDays, gapKm),
          (d, late) => ForecastItem(date: d, kind: ForecastKind.service, amount: serviceCost, overdue: late), late: st.health == DueHealth.overdue);
    }

    // Parts changed on their own (those fitted at a service are in its bill).
    for (final st in parts) {
      final p = st.part;
      if (p.visitId != null || (p.nextDate == null && p.nextKm == null)) continue;
      final gapDays = p.nextDate?.difference(p.installedDate).inDays;
      final gapKm = p.nextKm != null && p.installedKm != null ? p.nextKm! - p.installedKm! : null;
      schedule(due(p.nextDate, p.nextKm), every(gapDays, gapKm),
          (d, late) => ForecastItem(date: d, kind: ForecastKind.part, amount: p.cost > 0 ? p.cost : null, part: p.type, overdue: late),
          late: st.health == DueHealth.overdue);
    }

    // Fuel and everyday costs: the last three months' pace, spread per month.
    for (final m in months) {
      if (fuelLast90 > 0) add(ForecastItem(date: m.month, kind: ForecastKind.fuel, amount: fuelLast90 / 3));
      if (regularLast90 > 0) add(ForecastItem(date: m.month, kind: ForecastKind.regular, amount: regularLast90 / 3));
    }
    return CostForecast._(months, kmPerDay);
  }

  /// km a day over the last six months of odometer readings in the fuel log.
  static double? _kmPerDay(List<Expense> fills, DateTime now) {
    final from = now.subtract(const Duration(days: 180));
    final readings = [for (final e in fills) if (e.odometer != null && !e.date.isBefore(from)) e]..sort((a, b) => a.date.compareTo(b.date));
    if (readings.length < 2) return null;
    final days = readings.last.date.difference(readings.first.date).inDays;
    final km = readings.map((e) => e.odometer!).reduce(math.max) - readings.map((e) => e.odometer!).reduce(math.min);
    return days <= 0 || km <= 0 ? null : km / days;
  }
}

extension on ExpenseCategory {
  /// Everyday costs the forecast averages (not fuel, papers or garage bills).
  bool get everyday => this != ExpenseCategory.fuel && this != ExpenseCategory.papers;
}

/// Sums for the forecast's monthly averages: fuel, and everyday costs that
/// were not part of a garage visit or a part fitting.
({double fuel, double regular}) recentSpend(List<Expense> expenses) {
  var fuel = 0.0, regular = 0.0;
  for (final e in expenses) {
    if (e.category == ExpenseCategory.fuel) {
      fuel += e.amount;
    } else if (e.category.everyday && e.visitId == null && e.partId == null) {
      regular += e.amount;
    }
  }
  return (fuel: fuel, regular: regular);
}
