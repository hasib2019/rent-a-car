import 'dart:math';

import '../core/catalog.dart';
import 'models.dart';
import 'repository.dart';

/// Sample books for personal mode: a family car and a motorbike with eight
/// months of fill-ups, servicing, papers and everyday costs.
Future<void> seedPersonalDemo(Repository repo, {required bool bangla}) async {
  final rnd = Random(7);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 240));
  String t(String bn, String en) => bangla ? bn : en;
  final pumps = [t('মেঘনা পেট্রোলিয়াম, বনানী', 'Meghna Petroleum, Banani'), t('ট্রাস্ট ফিলিং স্টেশন, বিজয় সরণি', 'Trust Filling Station, Bijoy Sarani'), t('পদ্মা অয়েল, মহাখালী', 'Padma Oil, Mohakhali')];
  // The last CNG station measures short: ~12 % more m³ on the bill for the same km.
  final cngPumps = [t('নাভানা সিএনজি, তেজগাঁও', 'Navana CNG, Tejgaon'), t('ইউনাইটেড সিএনজি, মহাখালী', 'United CNG, Mohakhali'), t('রূপসা সিএনজি, বাড্ডা', 'Rupsha CNG, Badda')];
  final converted = start.add(const Duration(days: 90));

  final car = await repo.saveVehicle(Vehicle(
    name: t('এক্সিও', 'Axio'),
    type: VehicleType.car,
    regNo: 'ঢাকা মেট্রো-গ ৩৪-৫৬৭৮',
    model: 'Toyota Axio 2016',
    year: 2016,
    color: t('সাদা', 'White'),
    fuel: FuelType.cng,
    conversionCost: 75000,
    monthlyBudget: 30000,
    purchasePrice: 2350000,
    purchaseDate: start.subtract(const Duration(days: 400)),
  ));
  final bike = await repo.saveVehicle(Vehicle(
    name: t('বাইক', 'Bike'),
    type: VehicleType.bike,
    regNo: 'ঢাকা মেট্রো-হ ১২-৩৪৫৬',
    model: 'Yamaha FZS V3',
    year: 2022,
    fuel: FuelType.octane,
  ));

  // Car, first three months on octane: a fill about every six days, ~12 km/L,
  // one partial top-up and one forgotten fill.
  var odo = 48200.0;
  var day = start;
  var i = 0;
  var topUp = 0.0; // what a partial fill left empty; the next full tank adds it
  while (true) {
    day = day.add(Duration(days: 5 + rnd.nextInt(3)));
    if (!day.isBefore(converted)) break;
    final km = 300 + rnd.nextInt(140).toDouble();
    odo += km;
    final kmpl = 11.4 + rnd.nextDouble() * 1.4;
    final partial = i == 5;
    final burnt = km / kmpl;
    final litres = double.parse((partial ? burnt * 0.5 : burnt + topUp).toStringAsFixed(1));
    topUp = partial ? burnt * 0.5 : 0;
    if (i == 9) {
      i++;
      continue; // forgotten fill-up: the next one is marked as missed
    }
    await repo.saveExpense(Expense(
      date: day,
      vehicleId: car,
      category: ExpenseCategory.fuel,
      amount: (litres * 125).roundToDouble(),
      quantity: litres,
      odometer: odo,
      unitPrice: 125,
      fuelType: FuelType.octane,
      fullTank: !partial,
      missed: i == 10,
      payMethod: i.isEven ? PayMethod.card : PayMethod.cash,
      place: pumps[i % pumps.length],
    ));
    i++;
  }

  // Then converted to CNG: a small tank every two or three days, ~13 km/m³.
  // The last fill runs poorly so the mileage warning shows.
  await repo.saveExpense(Expense(
      date: converted, vehicleId: car, category: ExpenseCategory.other, amount: 75000, note: t('সিএনজি কনভার্শন (সিলিন্ডারসহ)', 'CNG conversion (with cylinder)')));
  day = converted;
  i = 0;
  while (true) {
    day = day.add(Duration(days: 2 + rnd.nextInt(2)));
    if (day.isAfter(today.subtract(const Duration(days: 1)))) break;
    final km = 140 + rnd.nextInt(50).toDouble();
    odo += km;
    final pump = i % cngPumps.length;
    final last = day.isAfter(today.subtract(const Duration(days: 4)));
    final kmpm = last ? 10.0 : (12.4 + rnd.nextDouble() * 1.2) * (pump == 2 ? 0.88 : 1);
    final m3 = double.parse((km / kmpm).toStringAsFixed(1));
    await repo.saveExpense(Expense(
      date: day,
      vehicleId: car,
      category: ExpenseCategory.fuel,
      amount: (m3 * 43).roundToDouble(),
      quantity: m3,
      odometer: odo,
      unitPrice: 43,
      fuelType: FuelType.cng,
      payMethod: PayMethod.cash,
      place: cngPumps[pump],
      office: i % 3 == 0, // client visits: claimed from the office
    ));
    i++;
  }

  // Bike: a small tank every ten days, ~42 km/L.
  var bikeOdo = 12400.0;
  for (var d = start.add(const Duration(days: 3)); d.isBefore(today); d = d.add(Duration(days: 9 + rnd.nextInt(4)))) {
    final km = 330 + rnd.nextInt(80).toDouble();
    bikeOdo += km;
    final litres = double.parse((km / (40 + rnd.nextDouble() * 4)).toStringAsFixed(1));
    await repo.saveExpense(Expense(
      date: d,
      vehicleId: bike,
      category: ExpenseCategory.fuel,
      amount: (litres * 127).roundToDouble(),
      quantity: litres,
      odometer: bikeOdo,
      unitPrice: 127,
      fuelType: FuelType.octane,
      payMethod: PayMethod.bkash,
      place: pumps[2],
    ));
  }

  // Monthly costs of keeping the car in Dhaka.
  for (var m = DateTime(start.year, start.month); !m.isAfter(today); m = DateTime(m.year, m.month + 1)) {
    Future<void> cost(int day, ExpenseCategory c, double amount, String note, {bool office = false}) async {
      final d = DateTime(m.year, m.month, day);
      if (d.isBefore(start) || d.isAfter(today)) return;
      await repo.saveExpense(Expense(date: d, vehicleId: car, category: c, amount: amount, note: note, office: office));
    }

    await cost(1, ExpenseCategory.parking, 3000, t('অফিসের পার্কিং (মাসিক)', 'Office parking (monthly)'), office: true);
    await cost(12, ExpenseCategory.wash, 400, t('ফুল ওয়াশ', 'Full wash'));
    await cost(21, ExpenseCategory.toll, 80 + rnd.nextInt(3) * 40, t('এক্সপ্রেসওয়ে টোল', 'Expressway toll'), office: true);
  }
  // The family driver: a month's salary three days after each month worked,
  // an Eid bonus, and an advance this month.
  final driver = await repo.saveDriver(Driver(name: t('রহিম মিয়া', 'Rahim Mia'), phone: '01712-345678', joinDate: start, monthlySalary: 16000));
  Future<void> pay(DateTime d, double amount, ExpenseCategory c, String note) async {
    if (d.isAfter(today)) return;
    await repo.saveExpense(Expense(date: d, vehicleId: car, category: c, amount: amount, note: note, driverId: driver, payMethod: PayMethod.cash));
  }

  for (var n = 1; !DateTime(start.year, start.month + n, start.day).isAfter(today); n++) {
    await pay(DateTime(start.year, start.month + n, start.day + 3), 16000, ExpenseCategory.salary, t('বেতন · রহিম মিয়া', 'Salary · Rahim Mia'));
  }
  await pay(start.add(const Duration(days: 95)), 8000, ExpenseCategory.bonus, t('বোনাস · রহিম মিয়া', 'Bonus · Rahim Mia'));
  await pay(today.subtract(const Duration(days: 2)), 3000, ExpenseCategory.salary, t('অগ্রিম · রহিম মিয়া', 'Advance · Rahim Mia'));

  await repo.saveExpense(Expense(
      date: start.add(const Duration(days: 95)), vehicleId: car, category: ExpenseCategory.repair, amount: 2800, note: t('এসি গ্যাস রিফিল', 'AC gas refill')));

  // Two official services and a battery.
  Future<void> service(int dayOffset, double km, {bool next = false}) => repo.saveVisit(
        ServiceVisit(
          vehicleId: car,
          date: start.add(Duration(days: dayOffset)),
          odometer: km,
          kind: ServiceKind.official,
          workshop: t('নাভানা টয়োটা সার্ভিস, তেজগাঁও', 'Navana Toyota Service, Tejgaon'),
          title: t('৫,০০০ কিমি সার্ভিস', '5,000 km service'),
          labour: 1800,
          nextDate: next ? start.add(Duration(days: dayOffset + 120)) : null,
          nextKm: next ? km + 5000 : null,
        ),
        [
          Part(vehicleId: car, type: PartType.engineOil, detail: 'Toyota 5W-30, 4L', cost: 4200, installedDate: today, nextKm: km + 5000),
          Part(vehicleId: car, type: PartType.oilFilter, detail: 'Toyota genuine', cost: 750, installedDate: today, nextKm: km + 10000),
          if (next) Part(vehicleId: car, type: PartType.airFilter, cost: 1200, installedDate: today, nextKm: km + 15000),
        ],
      );
  await service(30, 50900);
  await service(150, 57700, next: true);
  await repo.savePart(Part(
    vehicleId: car,
    type: PartType.battery,
    detail: 'Rahimafrooz Lucas 55Ah',
    shop: t('বাংলামোটর ব্যাটারি হাউস', 'Banglamotor Battery House'),
    installedDate: start.add(const Duration(days: 70)),
    installedKm: 52000,
    cost: 9500,
    nextDate: start.add(const Duration(days: 70 + 730)),
    warrantyUntil: start.add(const Duration(days: 70 + 365)),
  ));

  // Papers: the tax token is due soon so the reminder shows.
  for (final (type, days, provider, cost) in [
    (PaperType.taxToken, 18, 'BRTA', 16500.0),
    (PaperType.fitness, 140, 'BRTA', 3500.0),
    (PaperType.insurance, 55, t('গ্রিন ডেল্টা ইন্স্যুরেন্স', 'Green Delta Insurance'), 2600.0),
    (PaperType.license, 900, 'BRTA', 4500.0),
  ]) {
    await repo.savePaper(Paper(vehicleId: car, type: type, expiry: today.add(Duration(days: days)), provider: provider, renewalCost: cost));
  }
  await repo.savePaper(Paper(vehicleId: bike, type: PaperType.taxToken, expiry: today.add(const Duration(days: 200)), provider: 'BRTA'));
}
