import 'dart:math';

import '../core/catalog.dart';
import '../core/format.dart';
import 'models.dart';
import 'repository.dart';

/// A road cost in a demo trip template.
typedef _Cost = (ExpenseCategory category, double amount, double? qty, String place, String? note);

/// A demo trip template: route, client, fare, length, cargo and its road costs.
class _DemoTrip {
  const _DemoTrip(this.origin, this.destination, this.client, this.phone, this.fare, this.km, this.days, this.costs, {this.goods});
  final String origin;
  final String destination;
  final String client;
  final String phone;
  final double fare;
  final double km;
  final int days;
  final List<_Cost> costs;
  final String? goods;
}

/// A part on a demo job card: type, price, brand, shop, warranty months.
typedef _DemoPart = (PartType type, double cost, String? detail, String? shop, int? warrantyMonths);

/// A demo garage visit.
class _DemoVisit {
  const _DemoVisit(this.kind, this.workshop, this.title, this.labour, this.parts, {this.mechanic, this.jobNo, this.schedule = false});
  final ServiceKind kind;
  final String workshop;
  final String title;
  final double labour;
  final List<_DemoPart> parts;
  final String? mechanic;
  final String? jobNo;

  /// Whether this visit sets the next general service.
  final bool schedule;
}

/// Fills an empty database with ~4 months of believable fleet activity so a
/// new owner can explore every screen before entering real data.
Future<void> seedDemoData(Repository repo, {required bool bangla}) async {
  final rnd = Random(42);
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final start = todayOnly.subtract(const Duration(days: 120));
  String t(String bn, String en) => bangla ? bn : en;

  // Car reserve hires (CNG gas ≈ ৳43/m³) and pickup goods trips (diesel ≈ ৳114/L).
  final carTrips = [
    _DemoTrip(t('ঢাকা', 'Dhaka'), t('কক্সবাজার', "Cox's Bazar"), t('রহমান সাহেবের পরিবার', 'Rahman family'), '01711-556677', 22000, 820, 3, [
      (ExpenseCategory.fuel, 3100, 72, t('কুমিল্লা', 'Cumilla'), null),
      (ExpenseCategory.toll, 240, null, t('মেঘনা-গোমতী ব্রিজ', 'Meghna-Gumti bridge'), t('যাওয়া-আসা', 'Both ways')),
      (ExpenseCategory.food, 900, null, t('চকরিয়া', 'Chakaria'), t('ড্রাইভারের খাওয়া', "Driver's meals")),
      (ExpenseCategory.food, 1200, null, t('কক্সবাজার', "Cox's Bazar"), t('ড্রাইভারের থাকা', "Driver's room")),
      (ExpenseCategory.allowance, 1500, null, '', t('৩ দিনের ভাতা', '3 days')),
      (ExpenseCategory.parking, 150, null, t('কলাতলী', 'Kolatoli'), null),
    ], goods: t('৫ জন যাত্রী', '5 passengers')),
    _DemoTrip(t('ঢাকা', 'Dhaka'), t('সিলেট', 'Sylhet'), t('শাহজালাল রেন্ট-এ-কার', 'Shahjalal Rent-a-Car'), '01819-223344', 12000, 480, 2, [
      (ExpenseCategory.fuel, 1800, 42, t('ভৈরব', 'Bhairab'), null),
      (ExpenseCategory.toll, 150, null, t('ভৈরব সেতু', 'Bhairab bridge'), null),
      (ExpenseCategory.food, 500, null, t('শ্রীমঙ্গল', 'Sreemangal'), null),
      (ExpenseCategory.commission, 1000, null, '', t('রেন্ট-এ-কার এজেন্টের কমিশন', 'Agent commission')),
      (ExpenseCategory.parking, 100, null, t('সিলেট শহর', 'Sylhet city'), null),
    ], goods: t('বিয়ের রিজার্ভ, ৪ জন', 'Wedding hire, 4 people')),
    _DemoTrip(t('মিরপুর', 'Mirpur'), t('গাজীপুর', 'Gazipur'), t('রহমান সাহেবের পরিবার', 'Rahman family'), '01711-556677', 4500, 70, 1, [
      (ExpenseCategory.fuel, 300, 7, t('টঙ্গী', 'Tongi'), null),
      (ExpenseCategory.allowance, 300, null, '', null),
      (ExpenseCategory.parking, 100, null, t('কমিউনিটি সেন্টার', 'Community centre'), null),
    ], goods: t('বিয়ের গাড়ি', 'Wedding car')),
    _DemoTrip(t('ঢাকা', 'Dhaka'), t('ময়মনসিংহ', 'Mymensingh'), t('গ্রিনলাইন এনজিও', 'Greenline NGO'), '01912-445566', 7000, 240, 1, [
      (ExpenseCategory.fuel, 950, 22, t('ভালুকা', 'Bhaluka'), null),
      (ExpenseCategory.food, 400, null, t('ত্রিশাল', 'Trishal'), null),
      (ExpenseCategory.road, 100, null, t('ময়মনসিংহ শহর', 'Mymensingh town'), t('লাইনম্যান', 'Lineman')),
    ], goods: t('অফিস ট্যুর, ৩ জন', 'Office tour, 3 people')),
  ];
  final pickupTrips = [
    _DemoTrip(t('কারওয়ান বাজার', 'Karwan Bazar'), t('নারায়ণগঞ্জ', 'Narayanganj'), t('আলম ট্রেডার্স', 'Alam Traders'), '01715-889900', 3500, 60, 1, [
      (ExpenseCategory.fuel, 1140, 10, t('যাত্রাবাড়ী', 'Jatrabari'), null),
      (ExpenseCategory.loading, 600, null, t('কারওয়ান বাজার', 'Karwan Bazar'), t('লেবার', 'Labour')),
      (ExpenseCategory.road, 200, null, t('পোস্তগোলা', 'Postogola'), null),
      (ExpenseCategory.food, 200, null, t('নারায়ণগঞ্জ', 'Narayanganj'), null),
    ], goods: t('৮০ বস্তা চাল', '80 bags of rice')),
    _DemoTrip(t('ঢাকা', 'Dhaka'), t('চট্টগ্রাম বন্দর', 'Chattogram port'), t('সাকিব এন্টারপ্রাইজ', 'Sakib Enterprise'), '01811-776655', 16000, 540, 2, [
      (ExpenseCategory.fuel, 5700, 50, t('কাঁচপুর', 'Kanchpur'), null),
      (ExpenseCategory.mobil, 650, 1, t('ফেনী', 'Feni'), t('মবিল টপ-আপ', 'Oil top-up')),
      (ExpenseCategory.toll, 350, null, t('মেঘনা-গোমতী ব্রিজ', 'Meghna-Gumti bridge'), null),
      (ExpenseCategory.toll, 300, null, t('বন্দর গেট', 'Port gate'), null),
      (ExpenseCategory.road, 500, null, t('সীতাকুণ্ড', 'Sitakunda'), null),
      (ExpenseCategory.food, 800, null, t('কুমিল্লা', 'Cumilla'), null),
      (ExpenseCategory.allowance, 800, null, '', t('২ দিনের ভাতা', '2 days')),
      (ExpenseCategory.commission, 1000, null, t('তেজগাঁও ট্রাক স্ট্যান্ড', 'Tejgaon truck stand'), t('দালালের কমিশন', "Broker's cut")),
      (ExpenseCategory.loading, 700, null, t('চট্টগ্রাম', 'Chattogram'), t('লেবার', 'Labour')),
    ], goods: t('১ টন রড', '1 t steel rods')),
    _DemoTrip(t('গাজীপুর', 'Gazipur'), t('সাভার', 'Savar'), t('রূপা গার্মেন্টস', 'Rupa Garments'), '01611-334455', 5000, 90, 1, [
      (ExpenseCategory.fuel, 1710, 15, t('আশুলিয়া', 'Ashulia'), null),
      (ExpenseCategory.loading, 400, null, t('গাজীপুর', 'Gazipur'), null),
      (ExpenseCategory.road, 200, null, t('বাইপাইল', 'Baipail'), null),
      (ExpenseCategory.food, 250, null, t('সাভার', 'Savar'), null),
    ], goods: t('১২০ কার্টন কাপড়', '120 cartons of garments')),
    _DemoTrip(t('ঢাকা', 'Dhaka'), t('ফরিদপুর', 'Faridpur'), t('রফিক স্টোর', 'Rafiq Store'), '01556-112299', 9000, 260, 1, [
      (ExpenseCategory.fuel, 3420, 30, t('মাওয়া', 'Mawa'), null),
      (ExpenseCategory.toll, 300, null, t('ঢাকা-মাওয়া এক্সপ্রেসওয়ে', 'Dhaka-Mawa expressway'), null),
      (ExpenseCategory.toll, 1300, null, t('পদ্মা সেতু', 'Padma bridge'), null),
      (ExpenseCategory.food, 500, null, t('ভাঙ্গা', 'Bhanga'), null),
      (ExpenseCategory.allowance, 500, null, '', null),
      (ExpenseCategory.loading, 500, null, t('ফরিদপুর', 'Faridpur'), null),
    ], goods: t('৬০ বস্তা সিমেন্ট', '60 bags of cement')),
  ];

  // vehicle index → day → trip starting that day; plus every day spent on a trip.
  final tripPlan = <int, Map<int, _DemoTrip>>{2: {}, 3: {}};
  final onTrip = <String>{};
  void plan(int v, int first, int step, List<_DemoTrip> templates) {
    var k = 0;
    for (var day = first; day < 118; day += step) {
      final trip = templates[k++ % templates.length];
      if (day + trip.days - 1 >= 118) break;
      tripPlan[v]![day] = trip;
      for (var i = 0; i < trip.days; i++) {
        onTrip.add('$v:${day + i}');
      }
    }
  }

  plan(2, 4, 9, carTrips);
  plan(3, 2, 6, pickupTrips);
  // The pickup left for Khulna yesterday and is still on the road.
  final running = _DemoTrip(t('ঢাকা', 'Dhaka'), t('খুলনা', 'Khulna'), t('সাকিব এন্টারপ্রাইজ', 'Sakib Enterprise'), '01811-776655', 14000, 0, 2, [
    (ExpenseCategory.fuel, 3420, 30, t('মাওয়া', 'Mawa'), null),
    (ExpenseCategory.toll, 1300, null, t('পদ্মা সেতু', 'Padma bridge'), null),
  ], goods: t('৯০ বস্তা সার', '90 bags of fertiliser'));
  tripPlan[3]![119] = running;
  onTrip.addAll(['3:119', '3:120']);

  // Garage visits by (vehicle, day). Workshops and shops are typical Dhaka names.
  final garage = t('মায়ের দোয়া অটো গ্যারেজ, মিরপুর-১', "Mayer Doa Auto Garage, Mirpur-1");
  final workshop = t('রহমান অটো ওয়ার্কশপ, তেজগাঁও', 'Rahman Auto Workshop, Tejgaon');
  final bangshal = t('হাজী অটো পার্টস, বংশাল', 'Haji Auto Parts, Bangshal');
  final mirpurShop = t('নিউ মডার্ন অটো পার্টস, মিরপুর', 'New Modern Auto Parts, Mirpur');
  final visits = <String, _DemoVisit>{
    '0:32': _DemoVisit(ServiceKind.local, garage, t('মবিল পরিবর্তন', 'Oil change'), 150, [
      (PartType.engineOil, 650, 'Shell 20W-50', mirpurShop, null),
    ], mechanic: t('মিস্ত্রি জসিম', 'Mechanic Jashim')),
    '1:70': _DemoVisit(ServiceKind.official, t('অনুমোদিত সার্ভিস সেন্টার, মিরপুর', 'Authorised service centre, Mirpur'), t('৩য় ফ্রি সার্ভিস', '3rd free service'), 0, [
      (PartType.engineOil, 700, t('কোম্পানির মবিল', 'Genuine oil'), null, null),
      (PartType.sparkPlug, 450, null, null, 6),
    ], jobNo: 'JC-24817', mechanic: t('অ্যাডভাইজার: তানভীর', 'Advisor: Tanvir'), schedule: true),
    '2:70': _DemoVisit(ServiceKind.official, t('অনুমোদিত সার্ভিস সেন্টার, তেজগাঁও', 'Authorised service centre, Tejgaon'), t('৫৫,০০০ কিমি সার্ভিস', '55,000 km service'), 2500, [
      (PartType.engineOil, 2800, 'Mobil 1 5W-30', null, null),
      (PartType.oilFilter, 650, t('জেনুইন', 'Genuine'), null, 6),
      (PartType.airFilter, 900, t('জেনুইন', 'Genuine'), null, 6),
    ], jobNo: 'TS-3391', mechanic: t('অ্যাডভাইজার: রাশেদ', 'Advisor: Rashed'), schedule: true),
    '3:45': _DemoVisit(ServiceKind.local, workshop, t('ক্লাচ প্লেট বদল', 'Clutch plate replaced'), 2500, [
      (PartType.clutchPlate, 4500, 'Valeo', bangshal, 6),
    ], mechanic: t('মিস্ত্রি কালু', 'Mechanic Kalu'), jobNo: 'R-118'),
    '3:100': _DemoVisit(ServiceKind.local, workshop, t('মবিল ও ফিল্টার', 'Oil and filter'), 300, [
      (PartType.engineOil, 1800, 'Castrol CRB 15W-40', bangshal, null),
      (PartType.oilFilter, 450, null, bangshal, null),
    ], mechanic: t('মিস্ত্রি কালু', 'Mechanic Kalu')),
  };
  // Parts bought and fitted without a garage visit.
  final singleParts = <String, List<_DemoPart>>{
    '0:60': [(PartType.airFilter, 450, null, mirpurShop, null)],
    '1:5': [(PartType.brakePad, 1200, null, mirpurShop, null)],
    '1:20': [(PartType.battery, 6500, t('হ্যামকো ১২ ভোল্ট', 'Hamko 12V'), t('ব্যাটারি ঘর, মিরপুর', 'Battery Ghor, Mirpur'), 12)],
    '1:95': [(PartType.engineOil, 700, 'Shell 20W-50', mirpurShop, null)],
    '2:15': [(PartType.brakePad, 3500, null, bangshal, 6)],
    '2:100': [(PartType.tyre, 9000, t('সামনের ২টি', 'Front pair'), t('টায়ার হাউস, বংশাল', 'Tyre House, Bangshal'), 12)],
    '3:30': [(PartType.fuelFilter, 900, null, bangshal, null)],
  };

  await repo.runInTransaction((txn) async {
    Future<int> insert(String table, Map<String, Object?> m) {
      m.remove('id');
      return txn.insert(table, m);
    }

    final drivers = [
      Driver(name: t('রফিকুল ইসলাম', 'Rafiqul Islam'), phone: '01711-234567', joinDate: start, openingDue: 500, licenseNo: 'DK0123456CL', licenseExpiry: todayOnly.add(const Duration(days: 18))),
      Driver(name: t('জামাল উদ্দিন', 'Jamal Uddin'), phone: '01819-445566', joinDate: start, licenseNo: 'DK0456789CL', licenseExpiry: todayOnly.add(const Duration(days: 400))),
      Driver(name: t('সুমন মিয়া', 'Sumon Mia'), phone: '01912-778899', joinDate: start, licenseNo: 'DK0789123LM', licenseExpiry: todayOnly.subtract(const Duration(days: 5))),
      Driver(name: t('কামাল হোসেন', 'Kamal Hossain'), phone: '01555-112233', joinDate: start, licenseNo: 'DK0321654HV', licenseExpiry: todayOnly.add(const Duration(days: 700))),
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
        chassisNo: 'MD2A27AY4JWF12345',
        engineNo: 'AYZWJF54321',
        color: t('সবুজ', 'Green'),
        year: today.year - 2,
        fuel: FuelType.cng,
        capacity: t('৩ যাত্রী', '3 passengers'),
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
        chassisNo: 'MD2A27AY8PWG67890',
        engineNo: 'AYZWPG09876',
        color: t('সবুজ', 'Green'),
        year: today.year,
        fuel: FuelType.cng,
        capacity: t('৩ যাত্রী', '3 passengers'),
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
        chassisNo: 'NZE161-7012345',
        engineNo: '1NZ-F123456',
        color: t('সাদা', 'White'),
        year: 2016,
        fuel: FuelType.cng,
        capacity: t('৪ সিট', '4 seats'),
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
        chassisNo: 'MAT445021J1A23456',
        engineNo: '275IDI-123456',
        color: t('সাদা', 'White'),
        year: today.year - 2,
        fuel: FuelType.diesel,
        capacity: t('১ টন', '1 t'),
      ),
    ];
    final vehicleIds = <int>[];
    for (final v in vehicles) {
      vehicleIds.add(await insert('vehicles', v.toMap()));
    }

    final odometer = [0.0, 0.0, 48200.0, 61500.0];
    var challan = 4100;

    Future<void> addTrip(int v, DateTime date, _DemoTrip tpl, {TripStatus status = TripStatus.done}) async {
      final startKm = odometer[v].roundToDouble();
      final onRoad = status == TripStatus.running;
      final endKm = onRoad ? null : startKm + tpl.km + rnd.nextInt(20);
      if (endKm != null) odometer[v] = endKm;
      final trip = Trip(
        vehicleId: vehicleIds[v],
        driverId: driverIds[v],
        startDate: date,
        endDate: tpl.days > 1 && !onRoad ? date.add(Duration(days: tpl.days - 1)) : null,
        origin: tpl.origin,
        destination: tpl.destination,
        client: tpl.client,
        clientPhone: tpl.phone,
        fare: tpl.fare + rnd.nextInt(3) * 500,
        startKm: startKm,
        endKm: endKm,
        status: status,
        goods: tpl.goods,
        challanNo: v == 3 ? 'CH-${challan++}' : null,
      );
      final id = await insert('trips', trip.toMap());
      await insert('incomes', Income(date: date, vehicleId: vehicleIds[v], driverId: driverIds[v], kind: IncomeKind.trip, amount: trip.earned, note: '${trip.route} · ${tpl.client}', tripId: id).toMap());
      for (final (cat, amount, qty, place, note) in tpl.costs) {
        await insert('expenses', Expense(
          date: date,
          vehicleId: vehicleIds[v],
          category: cat,
          amount: amount,
          quantity: qty,
          odometer: cat == ExpenseCategory.fuel ? endKm : null,
          place: place.isEmpty ? null : place,
          note: note,
          tripId: id,
        ).toMap());
      }

      // Advance up front; the rest after the trip, except some recent ones
      // where the party still owes.
      final advance = (trip.fare * (rnd.nextBool() ? 0.3 : 0.5) / 100).round() * 100.0;
      await insert('trip_payments', TripPayment(tripId: id, date: date, amount: advance, method: rnd.nextBool() ? PayMethod.bkash : PayMethod.cash, note: t('অগ্রিম', 'Advance')).toMap());
      final dayIndex = date.difference(start).inDays;
      final settled = !onRoad && (dayIndex < 95 ? rnd.nextDouble() < 0.9 : rnd.nextDouble() < 0.35);
      if (settled) {
        final paidOn = (trip.endDate ?? date).add(Duration(days: 1 + rnd.nextInt(4)));
        await insert('trip_payments', TripPayment(tripId: id, date: paidOn.isAfter(todayOnly) ? todayOnly : paidOn, amount: trip.fare - advance, method: PayMethod.values[rnd.nextInt(PayMethod.values.length)]).toMap());
      }
    }

    Map<String, Object?> partRow(int v, _DemoPart p, DateTime date, double? km, {int? visitId}) {
      final (type, cost, detail, shop, warrantyMonths) = p;
      return Part(
        vehicleId: vehicleIds[v],
        type: type,
        detail: detail,
        installedDate: date,
        installedKm: km,
        cost: cost,
        nextDate: type.months == null ? null : DateTime(date.year, date.month + type.months!, date.day),
        nextKm: km == null || type.km == null ? null : km + type.km!,
        visitId: visitId,
        shop: shop,
        warrantyUntil: warrantyMonths == null ? null : DateTime(date.year, date.month + warrantyMonths, date.day),
      ).toMap();
    }

    Future<void> addPart(int v, _DemoPart p, DateTime date, double? km, {int? visitId}) async {
      final row = partRow(v, p, date, km, visitId: visitId);
      final id = await insert('parts', row);
      final part = Part.fromMap({...row, 'id': id});
      if (part.cost > 0) {
        await insert('expenses', Expense(
          date: date,
          vehicleId: part.vehicleId,
          category: part.type.expenseCategory,
          amount: part.cost,
          odometer: km,
          note: part.detail,
          place: part.shop,
          partId: id,
        ).toMap());
      }
    }

    Future<void> addVisit(int v, DateTime date, _DemoVisit spec, double? km) async {
      final type = vehicles[v].type;
      final visit = ServiceVisit(
        vehicleId: vehicleIds[v],
        date: date,
        odometer: km,
        kind: spec.kind,
        workshop: spec.workshop,
        mechanic: spec.mechanic,
        jobNo: spec.jobNo,
        title: spec.title,
        labour: spec.labour,
        nextDate: spec.schedule ? DateTime(date.year, date.month + type.serviceMonths, date.day) : null,
        nextKm: spec.schedule && km != null ? km + type.serviceKm : null,
      );
      final id = await insert('service_visits', visit.toMap());
      if (spec.labour > 0) {
        await insert('expenses', Expense(date: date, vehicleId: vehicleIds[v], category: ExpenseCategory.servicing, amount: spec.labour, odometer: km, note: spec.title, visitId: id).toMap());
      }
      for (final p in spec.parts) {
        await addPart(v, p, date, km, visitId: id);
      }
    }

    for (var day = 0; day <= 120; day++) {
      final date = start.add(Duration(days: day));
      final isToday = _sameDay(date, today);
      for (var v = 0; v < vehicles.length; v++) {
        // On a hire/goods trip: no daily collection that day.
        if (onTrip.contains('$v:$day')) {
          final trip = tripPlan[v]?[day];
          if (trip != null) await addTrip(v, date, trip, status: identical(trip, running) ? TripStatus.running : TripStatus.done);
          await insert('incomes', Income(date: date, vehicleId: vehicleIds[v], driverId: driverIds[v], kind: IncomeKind.off, amount: 0, note: t('ট্রিপে ছিল', 'On a trip')).toMap());
          continue;
        }
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
      }

      for (var v = 0; v < vehicles.length; v++) {
        // CNG readings are not tracked, so their reminders run on dates; the
        // car and pickup also use the odometer.
        final km = v >= 2 ? odometer[v].roundToDouble() : null;
        final visit = visits['$v:$day'];
        if (visit != null) await addVisit(v, date, visit, km);
        for (final p in singleParts['$v:$day'] ?? const <_DemoPart>[]) {
          await addPart(v, p, date, km);
        }
        // Monthly check-up at the usual garage.
        if (date.day == 5) {
          await addVisit(
            v,
            date,
            _DemoVisit(ServiceKind.local, v < 2 ? garage : workshop, t('মাসিক সার্ভিসিং', 'Monthly service'), 1200 + rnd.nextInt(8) * 100.0, const [],
                mechanic: v < 2 ? t('মিস্ত্রি জসিম', 'Mechanic Jashim') : t('মিস্ত্রি কালু', 'Mechanic Kalu'), schedule: v == 0 || v == 3),
            km,
          );
          await insert('expenses', Expense(date: date, vehicleId: vehicleIds[v], category: ExpenseCategory.parking, amount: v < 2 ? 1500 : 2500, note: t('গ্যারেজ ভাড়া', 'Garage rent')).toMap());
        }
      }

      if (rnd.nextDouble() < 0.06) {
        final v = rnd.nextInt(vehicles.length);
        final cats = [ExpenseCategory.repair, ExpenseCategory.wash, ExpenseCategory.fine];
        final cat = cats[rnd.nextInt(cats.length)];
        final amount = switch (cat) {
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

    // Older fittings that are due now: the CNG cylinder's 5-year retest and
    // the pickup's air filter.
    await addPart(0, (PartType.cylinder, 0, null, t('আরপিজিসিএল অনুমোদিত সেন্টার', 'RPGCL approved centre'), null),
        DateTime(todayOnly.year - 5, todayOnly.month, todayOnly.day + 20), null);
    await addPart(3, (PartType.airFilter, 550, null, bangshal, null), todayOnly.subtract(const Duration(days: 190)), null);

    // A booking for next week: advance taken, no fare earned yet.
    final booked = Trip(
      vehicleId: vehicleIds[2],
      driverId: driverIds[2],
      startDate: todayOnly.add(const Duration(days: 4)),
      endDate: todayOnly.add(const Duration(days: 6)),
      origin: t('ঢাকা', 'Dhaka'),
      destination: t('বান্দরবান', 'Bandarban'),
      client: t('রহমান সাহেবের পরিবার', 'Rahman family'),
      clientPhone: '01711-556677',
      fare: 20000,
      status: TripStatus.booked,
      goods: t('৪ জন যাত্রী', '4 passengers'),
    );
    final bookedId = await insert('trips', booked.toMap());
    await insert('trip_payments', TripPayment(tripId: bookedId, date: todayOnly, amount: 5000, method: PayMethod.bkash, note: t('বুকিং অগ্রিম', 'Booking advance')).toMap());

    // Paper expiry reminders.
    final papers = [
      Paper(vehicleId: vehicleIds[0], type: PaperType.taxToken, expiry: today.add(const Duration(days: 12)), docNo: 'TT-1452866', provider: t('বিআরটিএ মিরপুর', 'BRTA Mirpur')),
      Paper(vehicleId: vehicleIds[0], type: PaperType.fitness, expiry: today.add(const Duration(days: 140)), docNo: 'FT-889201', provider: t('বিআরটিএ মিরপুর', 'BRTA Mirpur')),
      Paper(vehicleId: vehicleIds[1], type: PaperType.routePermit, expiry: today.add(const Duration(days: 25)), docNo: 'RP-55410', provider: t('ডিএমপি / বিআরটিএ', 'DMP / BRTA')),
      Paper(vehicleId: vehicleIds[2], type: PaperType.insurance, expiry: today.subtract(const Duration(days: 3)), docNo: 'POL-2207-118'),
      Paper(vehicleId: vehicleIds[2], type: PaperType.taxToken, expiry: today.add(const Duration(days: 210)), docNo: 'TT-3477120', provider: t('বিআরটিএ ইকুরিয়া', 'BRTA Ikuria')),
      Paper(vehicleId: vehicleIds[3], type: PaperType.fitness, expiry: today.add(const Duration(days: 64)), docNo: 'FT-662048', provider: t('বিআরটিএ তেজগাঁও', 'BRTA Tejgaon')),
    ];
    for (final p in papers) {
      await insert('papers', p.toMap());
    }
  });
}

bool _sameDay(DateTime a, DateTime b) => dbDate(a) == dbDate(b);
