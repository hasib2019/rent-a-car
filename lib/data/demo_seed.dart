import 'dart:math';

import '../core/catalog.dart';
import '../core/format.dart';
import 'models.dart';
import 'repository.dart';

/// Fills an empty database with ~4 months of believable fleet activity so a
/// new owner can explore every screen before entering real data.
Future<void> seedDemoData(Repository repo, {required bool bangla}) async {
  final rnd = Random(42);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 120));
  String t(String bn, String en) => bangla ? bn : en;

  await repo.runInTransaction((txn) async {
    Future<int> insert(String table, Map<String, Object?> m) {
      m.remove('id');
      return txn.insert(table, m);
    }

    final drivers = [
      Driver(name: t('রফিকুল ইসলাম', 'Rafiqul Islam'), phone: '01711-234567', joinDate: start, openingDue: 500),
      Driver(name: t('জামাল উদ্দিন', 'Jamal Uddin'), phone: '01819-445566', joinDate: start),
      Driver(name: t('সুমন মিয়া', 'Sumon Mia'), phone: '01912-778899', joinDate: start),
      Driver(name: t('কামাল হোসেন', 'Kamal Hossain'), phone: '01555-112233', joinDate: start),
    ];
    final driverIds = <int>[];
    for (final d in drivers) {
      driverIds.add(await insert('drivers', d.toMap()));
    }

    final vehicles = [
      Vehicle(
        name: t('সবুজ সিএনজি', 'Green CNG'),
        type: VehicleType.cng,
        regNo: t('ঢাকা মেট্রো-থ ১৪-৫২৮৬', 'Dhaka Metro-Tha 14-5286'),
        model: t('বাজাজ RE ৪ স্ট্রোক', 'Bajaj RE 4S'),
        purchasePrice: 1650000,
        purchaseDate: DateTime(today.year - 2, 3, 12),
        dailyTarget: 1100,
        driverId: driverIds[0],
      ),
      Vehicle(
        name: t('নতুন সিএনজি', 'New CNG'),
        type: VehicleType.cng,
        regNo: t('ঢাকা মেট্রো-থ ১৫-০৯৪১', 'Dhaka Metro-Tha 15-0941'),
        model: t('বাজাজ RE', 'Bajaj RE'),
        purchasePrice: 1800000,
        purchaseDate: DateTime(today.year, today.month - 5, 2),
        dailyTarget: 1200,
        driverId: driverIds[1],
      ),
      Vehicle(
        name: t('সাদা এক্সিও', 'White Axio'),
        type: VehicleType.car,
        regNo: t('ঢাকা মেট্রো-গ ৩৪-৭৭১২', 'Dhaka Metro-Ga 34-7712'),
        model: t('টয়োটা এক্সিও ২০১৬', 'Toyota Axio 2016'),
        purchasePrice: 1450000,
        purchaseDate: DateTime(today.year - 1, 8, 20),
        dailyTarget: 1800,
        driverId: driverIds[2],
      ),
      Vehicle(
        name: t('টাটা পিকআপ', 'Tata Pickup'),
        type: VehicleType.pickup,
        regNo: t('ঢাকা মেট্রো-ন ২২-৩৪০৮', 'Dhaka Metro-Na 22-3408'),
        model: t('টাটা এস', 'Tata Ace'),
        purchasePrice: 1150000,
        purchaseDate: DateTime(today.year - 1, 1, 5),
        dailyTarget: 1500,
        driverId: driverIds[3],
      ),
    ];
    final vehicleIds = <int>[];
    for (final v in vehicles) {
      vehicleIds.add(await insert('vehicles', v.toMap()));
    }

    final odometer = [0.0, 0.0, 48200.0, 61500.0];

    for (var day = 0; day <= 120; day++) {
      final date = start.add(Duration(days: day));
      final isToday = _sameDay(date, today);
      for (var v = 0; v < vehicles.length; v++) {
        // Leave a couple of vehicles un-collected today so "pending" shows.
        if (isToday && v >= 2) continue;
        final veh = vehicles[v];
        final roll = rnd.nextDouble();
        if (roll < 0.06 || (date.weekday == DateTime.friday && rnd.nextDouble() < 0.25)) {
          await insert('incomes', Income(date: date, vehicleId: vehicleIds[v], driverId: driverIds[v], kind: IncomeKind.off, amount: 0, note: t('গাড়ি বন্ধ', 'Off')).toMap());
          continue;
        }
        double paid = veh.dailyTarget;
        if (roll < 0.16) paid = veh.dailyTarget - (1 + rnd.nextInt(5)) * 100;
        if (roll > 0.97) paid = veh.dailyTarget + 200;
        await insert('incomes', Income(date: date, vehicleId: vehicleIds[v], driverId: driverIds[v], kind: IncomeKind.joma, target: veh.dailyTarget, amount: paid).toMap());

        // Owner pays the car's gas; the pickup driver buys most diesel himself.
        if (v >= 2 && rnd.nextDouble() < (v == 2 ? 0.4 : 0.14)) {
          final qty = v == 2 ? 10 + rnd.nextInt(6).toDouble() : 20 + rnd.nextInt(10).toDouble();
          odometer[v] += qty * (v == 2 ? 11.5 : 8.2) + rnd.nextInt(30);
          await insert('expenses', Expense(
            date: date,
            vehicleId: vehicleIds[v],
            category: ExpenseCategory.fuel,
            amount: (qty * (v == 2 ? 43 : 114)).roundToDouble(),
            quantity: qty,
            odometer: odometer[v].roundToDouble(),
            note: v == 2 ? t('সিএনজি গ্যাস', 'CNG gas') : t('ডিজেল', 'Diesel'),
          ).toMap());
        }

        // Trip income now and then for the car.
        if (v == 2 && rnd.nextDouble() < 0.05) {
          await insert('incomes', Income(date: date, vehicleId: vehicleIds[v], driverId: driverIds[v], kind: IncomeKind.trip, amount: 3500 + rnd.nextInt(4) * 500.0, note: t('বিয়ের রিজার্ভ', 'Wedding hire')).toMap());
        }
      }

      // Monthly / occasional costs.
      if (date.day == 5) {
        for (var v = 0; v < vehicles.length; v++) {
          await insert('expenses', Expense(date: date, vehicleId: vehicleIds[v], category: ExpenseCategory.servicing, amount: 1200 + rnd.nextInt(8) * 100.0, note: t('মাসিক সার্ভিসিং', 'Monthly service')).toMap());
          await insert('expenses', Expense(date: date, vehicleId: vehicleIds[v], category: ExpenseCategory.parking, amount: v < 2 ? 1500 : 2500, note: t('গ্যারেজ ভাড়া', 'Garage rent')).toMap());
        }
      }
      if (rnd.nextDouble() < 0.06) {
        final v = rnd.nextInt(vehicles.length);
        final cats = [ExpenseCategory.parts, ExpenseCategory.repair, ExpenseCategory.wash, ExpenseCategory.tyre, ExpenseCategory.fine];
        final cat = cats[rnd.nextInt(cats.length)];
        final amount = switch (cat) {
          ExpenseCategory.tyre => 4500.0 + rnd.nextInt(4) * 500,
          ExpenseCategory.parts => 800.0 + rnd.nextInt(20) * 100,
          ExpenseCategory.repair => 600.0 + rnd.nextInt(15) * 100,
          ExpenseCategory.fine => 1000.0 + rnd.nextInt(3) * 500,
          _ => 200.0 + rnd.nextInt(3) * 50,
        };
        await insert('expenses', Expense(date: date, vehicleId: vehicleIds[v], category: cat, amount: amount).toMap());
      }
      if (day == 40) {
        await insert('expenses', Expense(date: date, vehicleId: vehicleIds[0], category: ExpenseCategory.papers, amount: 6500, note: t('ট্যাক্স টোকেন ও ফিটনেস', 'Tax token & fitness')).toMap());
      }
      if (day % 30 == 20) {
        await insert('incomes', Income(date: date, vehicleId: vehicleIds[0], driverId: driverIds[0], kind: IncomeKind.due, amount: 1000, note: t('বাকি শোধ', 'Paid old due')).toMap());
      }
    }

    // Paper expiry reminders.
    final papers = [
      Paper(vehicleId: vehicleIds[0], type: PaperType.taxToken, expiry: today.add(const Duration(days: 12))),
      Paper(vehicleId: vehicleIds[0], type: PaperType.fitness, expiry: today.add(const Duration(days: 140))),
      Paper(vehicleId: vehicleIds[1], type: PaperType.routePermit, expiry: today.add(const Duration(days: 25))),
      Paper(vehicleId: vehicleIds[2], type: PaperType.insurance, expiry: today.subtract(const Duration(days: 3))),
      Paper(vehicleId: vehicleIds[2], type: PaperType.taxToken, expiry: today.add(const Duration(days: 210))),
      Paper(vehicleId: vehicleIds[3], type: PaperType.fitness, expiry: today.add(const Duration(days: 64))),
    ];
    for (final p in papers) {
      await insert('papers', p.toMap());
    }
  });
}

bool _sameDay(DateTime a, DateTime b) => dbDate(a) == dbDate(b);
