import 'package:flutter/foundation.dart';

import '../data/demo_seed.dart';
import '../data/models.dart';
import '../data/personal_demo_seed.dart';
import '../data/repository.dart';
import '../services/settings.dart';

/// Holds the small, frequently used lists (vehicles, drivers, dues) in memory
/// and a [revision] counter that screens watch to re-run their queries.
///
/// There is one per [AppMode], each on its own database; the active one is
/// what screens get from the provider, so every screen works in both modes.
class AppState extends ChangeNotifier {
  AppState(this.repo, {this.personal = false});

  final Repository repo;

  /// The owner's own cars rather than the fleet business.
  final bool personal;

  List<Vehicle> vehicles = [];
  List<Driver> drivers = [];
  Map<int, double> dues = {};
  int revision = 0;
  bool loaded = false;

  Future<void> refresh() async {
    final results = await Future.wait([repo.vehicles(), repo.drivers(), repo.driverDues()]);
    vehicles = results[0] as List<Vehicle>;
    drivers = results[1] as List<Driver>;
    dues = results[2] as Map<int, double>;
    revision++;
    loaded = true;
    notifyListeners();
  }

  Vehicle? vehicle(int? id) {
    if (id == null) return null;
    for (final v in vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  Driver? driver(int? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  Driver? driverOf(Vehicle v) => driver(v.driverId);

  Vehicle? vehicleOfDriver(int driverId) {
    for (final v in vehicles) {
      if (v.driverId == driverId) return v;
    }
    return null;
  }

  List<Vehicle> get activeVehicles => vehicles.where((v) => v.isActive).toList();

  double get totalDue => dues.values.where((d) => d > 0).fold(0.0, (a, b) => a + b);

  /// Wraps any write so every listening screen refreshes afterwards.
  Future<T> mutate<T>(Future<T> Function(Repository r) action) async {
    final out = await action(repo);
    await refresh();
    return out;
  }

  Future<void> loadDemo({required bool bangla}) =>
      mutate((r) => personal ? seedPersonalDemo(r, bangla: bangla) : seedDemoData(r, bangla: bangla));
}

/// Both books, for the few places that act on all data at once (deleting the
/// account, the daily Drive backup).
class AppBooks {
  const AppBooks({required this.fleet, required this.personal});
  final AppState fleet;
  final AppState personal;

  AppState of(AppMode mode) => mode == AppMode.personal ? personal : fleet;
  List<AppState> get all => [fleet, personal];
}
