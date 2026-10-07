/// Feature keys the backend can switch on or off per package. They must match
/// backend/config/features.php.
abstract final class Feature {
  static const dailyCollection = 'daily_collection';
  static const driverDues = 'driver_dues';
  static const fuelExpense = 'fuel_expense';
  static const trips = 'trips';
  static const parties = 'parties';
  static const serviceVisits = 'service_visits';
  static const partsTracking = 'parts_tracking';
  static const papers = 'papers';
  static const reports = 'reports';
  static const backupDrive = 'backup_drive';
  static const backupFile = 'backup_file';
}

/// What the signed-in user may use. Packages are never shown in the app —
/// only their effect. Anything the server didn't mention is allowed, so a
/// user without a package (or an older server) keeps full access.
class Access {
  const Access({this.mode = 'full', this.features = const {}, this.maxVehicles, this.maxDrivers, this.expiresAt});

  static const full = Access();

  final String mode;
  final Map<String, bool> features;
  final int? maxVehicles;
  final int? maxDrivers;
  final DateTime? expiresAt;

  bool can(String feature) => features[feature] ?? true;

  bool canAddVehicle(int current) => maxVehicles == null || current < maxVehicles!;
  bool canAddDriver(int current) => maxDrivers == null || current < maxDrivers!;

  factory Access.fromJson(Map<String, dynamic>? json) {
    if (json == null) return full;
    final limits = (json['limits'] as Map?) ?? const {};
    final features = <String, bool>{};
    (json['features'] as Map?)?.forEach((k, v) => features[k.toString()] = v == true);
    return Access(
      mode: json['mode'] as String? ?? 'full',
      features: features,
      maxVehicles: (limits['max_vehicles'] as num?)?.toInt(),
      maxDrivers: (limits['max_drivers'] as num?)?.toInt(),
      expiresAt: json['expires_at'] == null ? null : DateTime.tryParse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'features': features,
        'limits': {'max_vehicles': maxVehicles, 'max_drivers': maxDrivers},
        'expires_at': expiresAt?.toIso8601String(),
      };
}
