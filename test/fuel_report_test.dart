import 'package:flutter_test/flutter_test.dart';
import 'package:gari_khata/core/catalog.dart';
import 'package:gari_khata/data/fuel_report.dart';
import 'package:gari_khata/data/models.dart';

Expense fill(int day, double odo, double litres, {bool full = true, bool missed = false, double price = 125, FuelType? fuel, int? id, String? at}) => Expense(
      id: id,
      date: DateTime(2026, 10, day),
      vehicleId: 1,
      category: ExpenseCategory.fuel,
      amount: litres * price,
      quantity: litres,
      odometer: odo,
      fullTank: full,
      missed: missed,
      unitPrice: price,
      fuelType: fuel,
      place: at,
    );

void main() {
  test('mileage is measured from full tank to full tank', () {
    final r = FuelReport.build([
      fill(1, 10000, 30),
      fill(5, 10400, 40), // 400 km on 40 L
      fill(9, 10700, 10, full: false),
      fill(12, 11000, 20), // 600 km on 10 + 20 L
    ]);
    expect(r.segments.length, 2);
    expect(r.fills[1].mileage, 10);
    expect(r.fills[2].mileage, isNull);
    expect(r.fills[3].mileage, 20);
    expect(r.avgMileage, 1000 / 70);
    expect(r.costPerKm, 70 * 125 / 1000);
    expect(r.bestMileage, 20);
    expect(r.worstMileage, 10);
    expect(r.trackedDistance, 1000);
  });

  test('a missed fill-up breaks the stretch, the next full tank restarts it', () {
    final r = FuelReport.build([
      fill(1, 10000, 30),
      fill(5, 10400, 40, missed: true), // not measurable
      fill(9, 10800, 40), // 400 km on 40 L
    ]);
    expect(r.fills[1].mileage, isNull);
    expect(r.fills[2].mileage, 10);
    expect(r.segments.length, 1);
  });

  test('entries are ordered by date, then odometer', () {
    final r = FuelReport.build([fill(5, 10400, 40), fill(1, 10000, 30)]);
    expect(r.fills.first.odometer, 10000);
    expect(r.lastMileage, 10);
  });

  test('flags a clear mileage drop and an overdue log', () {
    final r = FuelReport.build([
      fill(1, 10000, 30),
      fill(4, 10400, 40), // 10
      fill(7, 10800, 40), // 10
      fill(10, 11100, 40), // 7.5
    ]);
    expect(r.mileageDrop, closeTo(0.25, 1e-9));
    expect(r.mileageAlert, isTrue);
    expect(r.avgDaysBetween, 3);
    expect(r.overdueLog(DateTime(2026, 10, 15)), isFalse);
    expect(r.overdueLog(DateTime(2026, 10, 25)), isTrue);
  });

  test('bi-fuel cars get one report per fuel', () {
    final reports = FuelReport.byFuel([
      fill(1, 10000, 10, fuel: FuelType.cng, price: 43),
      fill(2, 10100, 10, fuel: FuelType.cng, price: 43),
      fill(3, 10200, 10, fuel: FuelType.cng, price: 43),
      fill(4, 10300, 20),
    ], fallback: FuelType.octane);
    expect(reports.map((r) => r.fuel), [FuelType.cng, FuelType.octane]);
    expect(reports.first.avgMileage, 10);
  });

  test('previews the mileage of an unsaved fill', () {
    final r = FuelReport.build([fill(1, 10000, 30, id: 1)]);
    expect(r.previewMileage(fill(3, 10500, 50)), 10);
    expect(r.previewMileage(fill(3, 10500, 50, full: false)), isNull);
  });

  test('monthly spend and distance', () {
    final r = FuelReport.build([fill(1, 10000, 30), fill(5, 10400, 40)]);
    final m = r.months(count: 2, until: DateTime(2026, 10, 20));
    expect(m.last.cost, 70 * 125);
    expect(m.last.distance, 400);
    expect(m.last.fills, 2);
    expect(m.first.cost, 0);
  });

  test('ranks pumps by the mileage their fuel gives; mixed stretches do not count', () {
    final r = FuelReport.build([
      fill(1, 10000, 30, at: 'Meghna'),
      fill(3, 10400, 40, at: 'Meghna'), // 10
      fill(5, 10800, 40, at: 'X Pump'), // 10
      fill(7, 11160, 40, at: 'x pump '), // 9
      fill(9, 11500, 20, full: false, at: 'Meghna'),
      fill(11, 11900, 20, at: 'X Pump'), // mixed: ignored
      fill(13, 12360, 40, at: 'meghna'), // 11.5
    ]);
    final st = r.stations();
    expect(st.map((s) => s.stretches), [2, 2]);
    expect(st.first.name, 'X Pump');
    expect(st.first.mileage, 760 / 80);
    expect(st.last.mileage, 860 / 80);
    expect(st.first.shortfall, greaterThan(0));
  });

  test('a CNG-converted car saves the cost-per-km gap on every CNG km', () {
    final octane = FuelReport.build([fill(1, 10000, 30), fill(5, 10400, 40)]); // ৳12.5/km
    final cng = FuelReport.build([
      fill(10, 10400, 10, price: 40, fuel: FuelType.cng),
      fill(20, 10800, 32, price: 40, fuel: FuelType.cng), // 400 km, ৳3.2/km
    ], fuel: FuelType.cng);
    final sv = FuelSavings.of([octane, cng])!;
    expect(sv.cheap, same(cng));
    expect(sv.distance, 400);
    expect(sv.saved, closeTo(400 * (12.5 - 3.2), 1e-6));
    expect(sv.paybackDate(sv.saved / 2, DateTime(2026, 10, 30)), isNull);
    expect(sv.paybackDate(sv.saved * 2, DateTime(2026, 10, 30)), DateTime(2026, 11, 19));
    expect(FuelSavings.of([octane]), isNull);
  });
}
