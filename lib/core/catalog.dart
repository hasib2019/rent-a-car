import 'package:flutter/material.dart';

import 'l10n.dart';

/// Vehicle kinds common in Bangladeshi small-fleet businesses.
enum VehicleType {
  cng('cng', 'সিএনজি', 'CNG', Icons.electric_rickshaw_rounded, Color(0xFF22C17A)),
  car('car', 'প্রাইভেট কার', 'Car', Icons.directions_car_filled_rounded, Color(0xFF4C7DFF)),
  pickup('pickup', 'পিকআপ', 'Pickup', Icons.local_shipping_rounded, Color(0xFFFF8A3D)),
  microbus('microbus', 'মাইক্রোবাস', 'Microbus', Icons.airport_shuttle_rounded, Color(0xFFA06BFF)),
  bus('bus', 'বাস', 'Bus', Icons.directions_bus_filled_rounded, Color(0xFFFF4F7B)),
  bike('bike', 'মোটরসাইকেল', 'Motorbike', Icons.two_wheeler_rounded, Color(0xFF14B8C9)),
  other('other', 'অন্যান্য', 'Other', Icons.commute_rounded, Color(0xFF8A8F98));

  const VehicleType(this.key, this.bn, this.en, this.icon, this.color);
  final String key;
  final String bn;
  final String en;
  final IconData icon;
  final Color color;

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
  servicing('servicing', 'সার্ভিসিং', 'Servicing', Icons.build_circle_rounded, Color(0xFF4C7DFF)),
  parts('parts', 'পার্টস', 'Spare parts', Icons.settings_rounded, Color(0xFFA06BFF)),
  tyre('tyre', 'টায়ার', 'Tyres', Icons.tire_repair_rounded, Color(0xFF14B8C9)),
  repair('repair', 'মেরামত', 'Repair', Icons.handyman_rounded, Color(0xFFFF4F7B)),
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
      this == servicing || this == parts || this == tyre || this == repair || this == wash;
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
