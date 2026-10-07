import 'package:flutter_test/flutter_test.dart';
import 'package:gari_khata/services/access.dart';
import 'package:gari_khata/ui/screens/auth_screens.dart';

void main() {
  group('Access', () {
    test('no data means full access', () {
      expect(Access.full.can(Feature.reports), isTrue);
      expect(Access.fromJson(null).canAddVehicle(999), isTrue);
    });

    test('package features and limits come from the server', () {
      final a = Access.fromJson({
        'mode': 'package',
        'features': {'reports': false, 'trips': true},
        'limits': {'max_vehicles': 2, 'max_drivers': null},
        'expires_at': '2026-12-01T00:00:00+06:00',
      });
      expect(a.can(Feature.reports), isFalse);
      expect(a.can(Feature.trips), isTrue);
      // Keys the server doesn't know about stay open.
      expect(a.can('something_new'), isTrue);
      expect(a.canAddVehicle(1), isTrue);
      expect(a.canAddVehicle(2), isFalse);
      expect(a.canAddDriver(50), isTrue);
      expect(Access.fromJson(a.toJson()).can(Feature.reports), isFalse);
    });
  });

  test('phone numbers are normalised like the backend', () {
    expect(normalizePhone('+880 1711-234567'), '01711234567');
    expect(normalizePhone('০১৭১১২৩৪৫৬৭'), '01711234567');
    expect(normalizePhone('8801911000000'), '01911000000');
  });
}
