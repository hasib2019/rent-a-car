import 'package:flutter_test/flutter_test.dart';
import 'package:gari_khata/core/catalog.dart';
import 'package:gari_khata/data/models.dart';
import 'package:gari_khata/data/ownership.dart';

void main() {
  test('budget projects the month-end spend from this month\'s pace', () {
    final b = BudgetStatus(budget: 30000, spent: 15000, today: DateTime(2026, 10, 10));
    expect(b.projected, 15000 / 10 * 31);
    expect(b.level, BudgetLevel.watch);
    expect(b.daysLeft, 22);
    expect(b.perDayLeft, 15000 / 22);
    expect(BudgetStatus(budget: 30000, spent: 5000, today: DateTime(2026, 10, 20)).level, BudgetLevel.ok);
    expect(BudgetStatus(budget: 30000, spent: 31000, today: DateTime(2026, 10, 20)).level, BudgetLevel.over);
    // A big bill on day 2 is not a pace.
    expect(BudgetStatus(budget: 30000, spent: 20000, today: DateTime(2026, 10, 2)).projected, 20000);
  });

  test('car value: the owner\'s figure, else 10 % a year declining', () {
    final v = Vehicle(name: 'A', type: VehicleType.car, purchasePrice: 2000000, purchaseDate: DateTime(2024, 10, 22));
    final est = CarValue.of(v, today: DateTime(2026, 10, 22))!;
    expect(est.estimated, isTrue);
    expect(est.now, closeTo(2000000 * 0.9 * 0.9, 2000));
    expect(est.lost, closeTo(380000, 2000));
    expect(est.perDay, closeTo(380000 / 730, 5));
    final own = CarValue.of(Vehicle(name: 'A', type: VehicleType.car, purchasePrice: 2000000, purchaseDate: DateTime(2024, 10, 22), marketValue: 1700000),
        today: DateTime(2026, 10, 22))!;
    expect(own.estimated, isFalse);
    expect(own.lost, 300000);
    expect(CarValue.of(Vehicle(name: 'A', type: VehicleType.car)), isNull);
  });

  test('salary: due per month worked, advances go negative, bonuses do not count', () {
    final d = Driver(name: 'Rahim', joinDate: DateTime(2026, 7, 1), monthlySalary: 15000, openingDue: 2000);
    Expense pay(int m, int day, double amt, {ExpenseCategory c = ExpenseCategory.salary}) =>
        Expense(date: DateTime(2026, m, day), vehicleId: 1, category: c, amount: amt, driverId: 1);
    final a = SalaryAccount.build(d, [pay(8, 2, 17000), pay(9, 1, 15000), pay(9, 20, 5000, c: ExpenseCategory.bonus), pay(10, 1, 15000), pay(10, 10, 4000)],
        today: DateTime(2026, 10, 22));
    expect(a.completed, 3); // July, August, September
    expect(a.earned, 2000 + 45000);
    expect(a.paid, 51000);
    expect(a.bonus, 5000);
    expect(a.balance, -4000);
    expect(a.advance, isTrue);
    expect(a.nextPayDay, DateTime(2026, 11, 1));
    // 2,000 opening + 45,000 for three months are settled; 4,000 is ahead.
    expect(a.months.take(3).map((m) => m.paid), [15000, 15000, 15000]);
    expect(a.current.paid, 4000);
    expect(a.months.length, 4);
  });
}
