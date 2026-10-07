import 'package:flutter/material.dart';

import '../services/analytics.dart';
import 'screens/auth_screens.dart';
import 'screens/backup_screen.dart';
import 'screens/daily_collection_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/driver_screens.dart';
import 'screens/entry_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/parties_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/service_screens.dart';
import 'screens/settings_screen.dart';
import 'screens/trip_screens.dart';
import 'screens/vehicle_screens.dart';

/// Analytics key for a pushed page. Type literals (not runtimeType strings)
/// so names survive minified web builds.
String? screenNameOf(Widget page) {
  if (page is EntryScreen) return 'entry_${page.mode.name}';
  return const <Type, String>{
    DailyCollectionScreen: 'daily_collection',
    VehicleDetailScreen: 'vehicle_detail',
    VehicleFormScreen: 'vehicle_form',
    DriverDetailScreen: 'driver_detail',
    DriverFormScreen: 'driver_form',
    TripsScreen: 'trips',
    TripDetailScreen: 'trip_detail',
    TripFormScreen: 'trip_form',
    PartiesScreen: 'parties',
    PartyDetailScreen: 'party_detail',
    MaintenanceScreen: 'maintenance',
    PartFormScreen: 'part_form',
    VisitDetailScreen: 'visit_detail',
    VisitFormScreen: 'visit_form',
    DocumentsScreen: 'documents',
    BackupScreen: 'backup',
    SettingsScreen: 'settings',
    ProfileScreen: 'profile',
    ForgotPasswordScreen: 'forgot_password',
  }[page.runtimeType];
}

/// MaterialPageRoute that reports the screen it shows, once, when first built.
class AppRoute<T> extends MaterialPageRoute<T> {
  AppRoute({required super.builder, super.fullscreenDialog});

  bool _tracked = false;

  @override
  Widget buildContent(BuildContext context) {
    final page = super.buildContent(context);
    if (!_tracked) {
      _tracked = true;
      final name = screenNameOf(page);
      if (name != null) Analytics.instance.screen(name);
    }
    return page;
  }
}
