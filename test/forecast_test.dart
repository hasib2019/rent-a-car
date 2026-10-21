import 'package:flutter_test/flutter_test.dart';
import 'package:gari_khata/core/catalog.dart';
import 'package:gari_khata/data/forecast.dart';
import 'package:gari_khata/data/models.dart';

void main() {
  final today = DateTime(2026, 10, 22);
  // 40 km a day: 1,200 km in the 30 days before today.
  final fills = [
    Expense(date: DateTime(2026, 9, 22), vehicleId: 1, category: ExpenseCategory.fuel, amount: 4000, quantity: 32, odometer: 60000),
    Expense(date: today, vehicleId: 1, category: ExpenseCategory.fuel, amount: 4000, quantity: 32, odometer: 61200),
  ];

  CostForecast build({List<Paper> papers = const [], List<ServiceStatus> services = const [], List<VisitSummary> visits = const [], List<PartStatus> parts = const []}) =>
      CostForecast.build(
        today: today,
        papers: papers,
        services: services,
        visits: visits,
        parts: parts,
        fills: fills,
        currentKm: 61200,
        fuelLast90: 30000,
        regularLast90: 6000,
      );

  test('renewals land in their expiry month; a lapsed one is due now', () {
    final f = build(papers: [
      Paper(vehicleId: 1, type: PaperType.taxToken, expiry: DateTime(2026, 12, 10), renewalCost: 12000),
      Paper(vehicleId: 1, type: PaperType.insurance, expiry: DateTime(2026, 10, 1)),
    ]);
    expect(f.months.length, 12);
    expect(f.months[2].items.where((i) => i.paper == PaperType.taxToken).single.amount, 12000);
    final lapsed = f.months[0].items.where((i) => i.paper == PaperType.insurance).single;
    expect(lapsed.overdue, isTrue);
    expect(f.unknown, 1);
    expect(f.heaviest!.month, DateTime(2026, 12));
  });

  test('km schedules become dates from how far the car goes a day, and repeat', () {
    final visit = ServiceVisit(vehicleId: 1, date: DateTime(2026, 9, 1), odometer: 59000, labour: 2000, nextKm: 64000);
    final f = build(services: [ServiceStatus(visit, currentKm: 61200)], visits: [VisitSummary(visit, partsCost: 4000)]);
    expect(f.kmPerDay, 40);
    final services = f.oneOffs.where((i) => i.kind == ForecastKind.service).toList();
    // 2,800 km to go at 40 km/day = 70 days; then every 5,000 km = 125 days.
    expect(services.first.date, today.add(const Duration(days: 70)));
    expect(services[1].date, today.add(const Duration(days: 195)));
    expect(services.first.amount, 6000);
  });

  test('fuel and everyday costs run at the last three months\' pace', () {
    final f = build();
    expect(f.months.first.total, 10000 + 2000);
    expect(f.total, 12 * 12000);
  });

  test('recentSpend leaves garage bills to the service schedule', () {
    final s = recentSpend([
      Expense(date: today, vehicleId: 1, category: ExpenseCategory.fuel, amount: 100),
      Expense(date: today, vehicleId: 1, category: ExpenseCategory.parking, amount: 50),
      Expense(date: today, vehicleId: 1, category: ExpenseCategory.servicing, amount: 999, visitId: 3),
      Expense(date: today, vehicleId: 1, category: ExpenseCategory.papers, amount: 999),
    ]);
    expect(s.fuel, 100);
    expect(s.regular, 50);
  });
}
