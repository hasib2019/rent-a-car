import 'dart:math' as math;

import 'package:flutter/material.dart' show DateUtils;

import '../core/catalog.dart';
import 'models.dart';

enum BudgetLevel { ok, watch, over }

/// This month's spend against the owner's monthly budget, and where the
/// current pace will land by the month's end.
class BudgetStatus {
  BudgetStatus({required this.budget, required this.spent, DateTime? today}) : today = DateUtils.dateOnly(today ?? DateTime.now());

  final double budget;
  final double spent;
  final DateTime today;

  int get daysInMonth => DateUtils.getDaysInMonth(today.year, today.month);

  /// Days left including today.
  int get daysLeft => daysInMonth - today.day + 1;

  double get used => budget <= 0 ? 0 : spent / budget;
  double get left => budget - spent;

  /// Month-end spend at this month's pace. Big one-off bills early in the
  /// month would overstate it, so the first week only counts what is spent.
  double get projected => today.day < 7 ? spent : spent / today.day * daysInMonth;

  /// What may still be spent per day to stay within budget.
  double get perDayLeft => left <= 0 ? 0 : left / daysLeft;

  BudgetLevel get level {
    if (spent > budget) return BudgetLevel.over;
    if (used >= 0.8 || projected > budget) return BudgetLevel.watch;
    return BudgetLevel.ok;
  }
}

/// What the car is worth now and what it has lost since it was bought.
/// Without the owner's own figure the value is estimated at [yearlyLoss] a
/// year on a declining balance (Bangladeshi cars hold value well).
class CarValue {
  CarValue._({required this.price, required this.bought, required this.now, required this.estimated, required this.today});

  static const yearlyLoss = 0.10;

  final double price;
  final DateTime bought;
  final double now;

  /// True when [now] is the app's estimate rather than the owner's figure.
  final bool estimated;
  final DateTime today;

  static CarValue? of(Vehicle v, {DateTime? today}) {
    final t = DateUtils.dateOnly(today ?? DateTime.now());
    if (v.purchasePrice <= 0 || v.purchaseDate == null || v.purchaseDate!.isAfter(t)) return null;
    final years = t.difference(v.purchaseDate!).inDays / 365.25;
    final own = v.marketValue != null && v.marketValue! > 0;
    final now = own ? v.marketValue! : v.purchasePrice * math.pow(1 - yearlyLoss, years);
    return CarValue._(price: v.purchasePrice, bought: v.purchaseDate!, now: now.toDouble(), estimated: !own, today: t);
  }

  double get lost => math.max(0, price - now);
  double get lostShare => price <= 0 ? 0 : lost / price;
  int get daysOwned => math.max(1, today.difference(bought).inDays);

  /// Value lost per day — the hidden cost of owning the car.
  double get perDay => lost / daysOwned;
  double get perMonth => perDay * 30.44;
}

/// One month of a salaried driver: what he earned and what he was paid.
class SalaryMonth {
  SalaryMonth(this.from, this.to, this.salary);
  final DateTime from;

  /// Exclusive end.
  final DateTime to;
  final double salary;
  double paid = 0;
  double bonus = 0;
}

/// A personal driver's account: opening due + a month's salary for every
/// month worked − salary and advances paid. Positive = still owed to him,
/// negative = he has taken an advance. Bonuses are costs, not salary.
///
/// Salary is paid after the month is worked, so payments settle the oldest
/// unpaid month first (the opening due before that); whatever is left over
/// is an advance against the month running now.
class SalaryAccount {
  SalaryAccount._(this.driver, this.months, this.paid, this.bonus, this.completed, this.nextPayDay);

  final Driver driver;

  /// Oldest first; the last one is the month running now.
  final List<SalaryMonth> months;
  final double paid;
  final double bonus;

  /// Months fully worked (each one's salary is due).
  final int completed;
  final DateTime nextPayDay;

  double get earned => driver.openingDue + driver.monthlySalary * completed;
  double get balance => earned - paid;
  bool get owed => balance > 0.5;
  bool get advance => balance < -0.5;
  SalaryMonth get current => months.last;

  static SalaryAccount build(Driver d, List<Expense> payments, {DateTime? today}) {
    final t = DateUtils.dateOnly(today ?? DateTime.now());
    final start = d.joinDate ?? (payments.isEmpty ? t : payments.first.date);
    DateTime nth(int n) => DateTime(start.year, start.month + n, start.day);
    var completed = 0;
    while (!nth(completed + 1).isAfter(t)) {
      completed++;
    }
    final months = [for (var i = 0; i <= completed; i++) SalaryMonth(nth(i), nth(i + 1), d.monthlySalary)];
    var paid = 0.0, bonus = 0.0;
    for (final p in payments) {
      if (p.category == ExpenseCategory.bonus) {
        bonus += p.amount;
        (months.where((m) => !p.date.isBefore(m.from) && p.date.isBefore(m.to)).firstOrNull ?? months.last).bonus += p.amount;
      } else {
        paid += p.amount;
      }
    }
    var pot = math.max(0.0, paid - d.openingDue);
    for (var i = 0; i < completed && pot > 0; i++) {
      final take = math.min(pot, months[i].salary);
      months[i].paid = take;
      pot -= take;
    }
    months.last.paid += pot;
    return SalaryAccount._(d, months, paid, bonus, completed, nth(completed + 1));
  }
}
