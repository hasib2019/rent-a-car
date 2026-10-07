import 'package:flutter/material.dart';

import 'l10n.dart';

/// Vehicle kinds common in Bangladeshi small-fleet businesses.
enum VehicleType {
  cng('cng', 'সিএনজি', 'CNG', Icons.electric_rickshaw_rounded, Color(0xFF22C17A), 2500, 2),
  car('car', 'প্রাইভেট কার', 'Car', Icons.directions_car_filled_rounded, Color(0xFF4C7DFF), 5000, 6),
  pickup('pickup', 'পিকআপ', 'Pickup', Icons.local_shipping_rounded, Color(0xFFFF8A3D), 5000, 3),
  microbus('microbus', 'মাইক্রোবাস', 'Microbus', Icons.airport_shuttle_rounded, Color(0xFFA06BFF), 5000, 3),
  bus('bus', 'বাস', 'Bus', Icons.directions_bus_filled_rounded, Color(0xFFFF4F7B), 10000, 3),
  bike('bike', 'মোটরসাইকেল', 'Motorbike', Icons.two_wheeler_rounded, Color(0xFF14B8C9), 2000, 3),
  other('other', 'অন্যান্য', 'Other', Icons.commute_rounded, Color(0xFF8A8F98), 5000, 6);

  const VehicleType(this.key, this.bn, this.en, this.icon, this.color, this.serviceKm, this.serviceMonths);
  final String key;
  final String bn;
  final String en;
  final IconData icon;
  final Color color;

  /// Typical general-service interval, used to pre-fill a service visit.
  final int serviceKm;
  final int serviceMonths;

  String label(S s) => s.bn ? bn : en;

  static VehicleType from(String? key) =>
      VehicleType.values.firstWhere((e) => e.key == key, orElse: () => VehicleType.other);
}

enum VehicleStatus {
  active('active'),
  garage('garage'),
  inactive('inactive');

  const VehicleStatus(this.key);
  final String key;

  String label(S s) => switch (this) {
        VehicleStatus.active => s.active,
        VehicleStatus.garage => s.inGarage,
        VehicleStatus.inactive => s.inactive,
      };

  static VehicleStatus from(String? key) =>
      VehicleStatus.values.firstWhere((e) => e.key == key, orElse: () => VehicleStatus.active);
}

/// What kind of money came in.
enum IncomeKind {
  /// Driver's daily hand-over against a target. Shortfall becomes driver due.
  joma('joma', 'দৈনিক জমা', 'Daily collection', Icons.payments_rounded),

  /// A hire / reserve / rental trip. Does not affect driver due.
  trip('trip', 'ট্রিপ আয়', 'Trip income', Icons.route_rounded),

  /// Driver paying back an old shortfall.
  due('due', 'বাকি আদায়', 'Due recovered', Icons.savings_rounded),

  /// Vehicle did not run that day (no target, no money).
  off('off', 'গাড়ি বন্ধ', 'Off day', Icons.do_not_disturb_on_rounded);

  const IncomeKind(this.key, this.bn, this.en, this.icon);
  final String key;
  final String bn;
  final String en;
  final IconData icon;

  String label(S s) => s.bn ? bn : en;

  static IncomeKind from(String? key) =>
      IncomeKind.values.firstWhere((e) => e.key == key, orElse: () => IncomeKind.joma);
}

/// Where the money goes.
enum ExpenseCategory {
  fuel('fuel', 'জ্বালানি', 'Fuel', Icons.local_gas_station_rounded, Color(0xFFFF8A3D)),
  mobil('mobil', 'মবিল / অয়েল', 'Engine oil', Icons.oil_barrel_rounded, Color(0xFFC77D1A)),
  servicing('servicing', 'সার্ভিসিং', 'Servicing', Icons.build_circle_rounded, Color(0xFF4C7DFF)),
  parts('parts', 'পার্টস', 'Spare parts', Icons.settings_rounded, Color(0xFFA06BFF)),
  tyre('tyre', 'টায়ার', 'Tyres', Icons.tire_repair_rounded, Color(0xFF14B8C9)),
  repair('repair', 'মেরামত', 'Repair', Icons.handyman_rounded, Color(0xFFFF4F7B)),
  toll('toll', 'টোল / ব্রিজ / ফেরি', 'Toll / bridge / ferry', Icons.toll_rounded, Color(0xFF0EA5A0)),
  road('road', 'রাস্তার খরচ', 'Road costs', Icons.add_road_rounded, Color(0xFFD9467A)),
  food('food', 'খাওয়া / থাকা', 'Food / lodging', Icons.restaurant_rounded, Color(0xFFF59E0B)),
  allowance('allowance', 'ড্রাইভারের ট্রিপ ভাতা', 'Driver trip allowance', Icons.wallet_rounded, Color(0xFF2DB37A)),
  commission('commission', 'কমিশন / দালালি', 'Commission', Icons.handshake_rounded, Color(0xFFB07A44)),
  loading('loading', 'লোড-আনলোড', 'Loading / labour', Icons.inventory_2_rounded, Color(0xFF7C8CF8)),
  papers('papers', 'কাগজপত্র', 'Papers & tax', Icons.description_rounded, Color(0xFFE5B812)),
  salary('salary', 'ড্রাইভার বেতন', 'Driver salary', Icons.badge_rounded, Color(0xFF22C17A)),
  wash('wash', 'ধোয়া-মোছা', 'Wash', Icons.local_car_wash_rounded, Color(0xFF5AC8FA)),
  parking('parking', 'পার্কিং / গ্যারেজ', 'Parking / garage', Icons.local_parking_rounded, Color(0xFF8E7DFF)),
  fine('fine', 'মামলা / জরিমানা', 'Case / fine', Icons.gavel_rounded, Color(0xFFE5484D)),
  installment('installment', 'কিস্তি', 'Loan instalment', Icons.account_balance_rounded, Color(0xFF6C717A)),
  other('other', 'অন্যান্য', 'Other', Icons.more_horiz_rounded, Color(0xFF8A8F98));

  const ExpenseCategory(this.key, this.bn, this.en, this.icon, this.color);
  final String key;
  final String bn;
  final String en;
  final IconData icon;
  final Color color;

  String label(S s) => s.bn ? bn : en;

  static ExpenseCategory from(String? key) =>
      ExpenseCategory.values.firstWhere((e) => e.key == key, orElse: () => ExpenseCategory.other);

  /// Categories counted as "repair & maintenance" in summaries.
  bool get isMaintenance =>
      this == mobil || this == servicing || this == parts || this == tyre || this == repair || this == wash;

  static List<ExpenseCategory> get maintenance => values.where((c) => c.isMaintenance).toList();

  /// Costs that typically come up on the road during a trip, in picker order.
  static const tripCosts = [fuel, mobil, toll, road, food, allowance, commission, loading, parking, repair, tyre, fine, other];
}

/// Where a trip stands. Only trips on the road or completed earn their fare;
/// a booking is not income yet and a cancelled trip never is.
enum TripStatus {
  booked('booked', 'বুকিং', 'Booked', Icons.event_available_rounded),
  running('running', 'চলমান', 'On the road', Icons.local_shipping_rounded),
  done('done', 'সম্পন্ন', 'Completed', Icons.check_circle_rounded),
  cancelled('cancelled', 'বাতিল', 'Cancelled', Icons.cancel_rounded);

  const TripStatus(this.key, this.bn, this.en, this.icon);
  final String key;
  final String bn;
  final String en;
  final IconData icon;

  String label(S s) => s.bn ? bn : en;

  bool get countsFare => this == running || this == done;

  static const earningKeys = "('running','done')";

  static TripStatus from(String? key) => TripStatus.values.firstWhere((e) => e.key == key, orElse: () => TripStatus.done);
}

/// How a party paid.
enum PayMethod {
  cash('cash', 'ক্যাশ', 'Cash', Icons.payments_rounded),
  bkash('bkash', 'বিকাশ', 'bKash', Icons.phone_android_rounded),
  nagad('nagad', 'নগদ', 'Nagad', Icons.phone_iphone_rounded),
  bank('bank', 'ব্যাংক', 'Bank', Icons.account_balance_rounded),
  cheque('cheque', 'চেক', 'Cheque', Icons.receipt_rounded);

  const PayMethod(this.key, this.bn, this.en, this.icon);
  final String key;
  final String bn;
  final String en;
  final IconData icon;

  String label(S s) => s.bn ? bn : en;

  static PayMethod from(String? key) => PayMethod.values.firstWhere((e) => e.key == key, orElse: () => PayMethod.cash);
}

/// Where a vehicle was serviced.
enum ServiceKind {
  official('official', 'অফিসিয়াল সার্ভিস সেন্টার', 'Authorised service centre', 'অফিসিয়াল সার্ভিস', 'Official', Icons.verified_rounded, Color(0xFF4C7DFF)),
  local('local', 'লোকাল গ্যারেজ / মিস্ত্রি', 'Local garage / mechanic', 'লোকাল গ্যারেজ', 'Local garage', Icons.garage_rounded, Color(0xFFFF8A3D));

  const ServiceKind(this.key, this.bn, this.en, this.bnShort, this.enShort, this.icon, this.color);
  final String key;
  final String bn;
  final String en;
  final String bnShort;
  final String enShort;
  final IconData icon;
  final Color color;

  String label(S s) => s.bn ? bn : en;
  String shortLabel(S s) => s.bn ? bnShort : enShort;

  static ServiceKind from(String? key) => ServiceKind.values.firstWhere((e) => e.key == key, orElse: () => ServiceKind.local);
}

enum FuelType {
  cng('cng', 'সিএনজি', 'CNG'),
  octane('octane', 'অকটেন', 'Octane'),
  petrol('petrol', 'পেট্রোল', 'Petrol'),
  diesel('diesel', 'ডিজেল', 'Diesel'),
  lpg('lpg', 'এলপিজি', 'LPG'),
  hybrid('hybrid', 'হাইব্রিড', 'Hybrid'),
  electric('electric', 'ইলেকট্রিক', 'Electric');

  const FuelType(this.key, this.bn, this.en);
  final String key;
  final String bn;
  final String en;

  String label(S s) => s.bn ? bn : en;

  static FuelType? from(String? key) {
    for (final f in FuelType.values) {
      if (f.key == key) return f;
    }
    return null;
  }
}

/// Wear parts an owner replaces on a schedule. [km] and [months] are typical
/// change intervals for Bangladeshi CNGs, cars and pickups; the owner can
/// override them per fitting.
enum PartType {
  engineOil('engine_oil', 'ইঞ্জিন অয়েল (মবিল)', 'Engine oil', Icons.water_drop_rounded, Color(0xFFC77D1A), 3000, 3, ExpenseCategory.mobil),
  oilFilter('oil_filter', 'অয়েল ফিল্টার', 'Oil filter', Icons.filter_alt_rounded, Color(0xFFA06BFF), 6000, 6, ExpenseCategory.parts),
  airFilter('air_filter', 'এয়ার ফিল্টার', 'Air filter', Icons.air_rounded, Color(0xFF5AC8FA), 10000, 6, ExpenseCategory.parts),
  fuelFilter('fuel_filter', 'ফুয়েল ফিল্টার', 'Fuel filter', Icons.local_gas_station_rounded, Color(0xFFFF8A3D), 15000, 12, ExpenseCategory.parts),
  sparkPlug('spark_plug', 'স্পার্ক প্লাগ', 'Spark plugs', Icons.bolt_rounded, Color(0xFFE5B812), 10000, 12, ExpenseCategory.parts),
  brakePad('brake_pad', 'ব্রেক প্যাড / শু', 'Brake pads / shoes', Icons.stop_circle_rounded, Color(0xFFE5484D), 20000, 12, ExpenseCategory.parts),
  clutchPlate('clutch_plate', 'ক্লাচ প্লেট', 'Clutch plate', Icons.album_rounded, Color(0xFF8E7DFF), 40000, null, ExpenseCategory.parts),
  gearOil('gear_oil', 'গিয়ার অয়েল', 'Gear oil', Icons.settings_rounded, Color(0xFF6C717A), 20000, 12, ExpenseCategory.mobil),
  coolant('coolant', 'কুল্যান্ট', 'Coolant', Icons.ac_unit_rounded, Color(0xFF14B8C9), null, 12, ExpenseCategory.parts),
  battery('battery', 'ব্যাটারি', 'Battery', Icons.battery_charging_full_rounded, Color(0xFF22C17A), null, 24, ExpenseCategory.parts),
  tyre('tyre', 'টায়ার', 'Tyres', Icons.tire_repair_rounded, Color(0xFF0EA5A0), 40000, 24, ExpenseCategory.tyre),
  belt('belt', 'ফ্যান / টাইমিং বেল্ট', 'Fan / timing belt', Icons.loop_rounded, Color(0xFF4C7DFF), 40000, 24, ExpenseCategory.parts),
  cylinder('cylinder', 'সিএনজি সিলিন্ডার রিটেস্ট', 'CNG cylinder retest', Icons.propane_tank_rounded, Color(0xFF22C17A), null, 60, ExpenseCategory.parts),
  other('other', 'অন্যান্য পার্টস', 'Other part', Icons.build_rounded, Color(0xFF8A8F98), null, null, ExpenseCategory.parts);

  const PartType(this.key, this.bn, this.en, this.icon, this.color, this.km, this.months, this.expenseCategory);
  final String key;
  final String bn;
  final String en;
  final IconData icon;
  final Color color;

  /// Typical change interval in km, if wear depends on distance.
  final int? km;

  /// Typical change interval in months, if wear depends on time.
  final int? months;

  /// Ledger category the fitting cost is booked under.
  final ExpenseCategory expenseCategory;

  String label(S s) => s.bn ? bn : en;

  static PartType from(String? key) => PartType.values.firstWhere((e) => e.key == key, orElse: () => PartType.other);
}

/// Papers with an expiry date that Bangladeshi vehicle owners must renew.
enum PaperType {
  taxToken('tax_token', 'ট্যাক্স টোকেন', 'Tax token'),
  fitness('fitness', 'ফিটনেস', 'Fitness certificate'),
  routePermit('route_permit', 'রুট পারমিট', 'Route permit'),
  insurance('insurance', 'ইন্স্যুরেন্স', 'Insurance'),
  registration('registration', 'রেজিস্ট্রেশন', 'Registration'),
  license('license', 'ড্রাইভিং লাইসেন্স', 'Driving licence'),
  other('other', 'অন্যান্য', 'Other');

  const PaperType(this.key, this.bn, this.en);
  final String key;
  final String bn;
  final String en;

  String label(S s) => s.bn ? bn : en;

  static PaperType from(String? key) =>
      PaperType.values.firstWhere((e) => e.key == key, orElse: () => PaperType.other);
}
