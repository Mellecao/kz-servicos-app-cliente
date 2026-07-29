import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/available_driver.dart';

void main() {
  group('AvailableDriver.fromMap', () {
    test('parseia row completo', () {
      final row = {
        'driver_profile_id': 'd1',
        'full_name': 'João Silva',
        'avatar_url': 'https://x.io/a.jpg',
        'average_rating': 4.8,
        'total_ratings': 127,
        'vehicles': [
          {
            'brand': 'Fiat',
            'model': 'Uno',
            'color': 'Prata',
            'license_plate': 'ABC1D23',
            'is_active': true,
          },
        ],
      };
      final d = AvailableDriver.fromMap(row);
      expect(d.driverProfileId, 'd1');
      expect(d.fullName, 'João Silva');
      expect(d.avatarUrl, 'https://x.io/a.jpg');
      expect(d.averageRating, 4.8);
      expect(d.totalRatings, 127);
      expect(d.vehicle?.brand, 'Fiat');
      expect(d.vehicle?.licensePlate, 'ABC1D23');
    });

    test('avatar_url null → propaga', () {
      final row = {
        'driver_profile_id': 'd1',
        'full_name': 'Maria',
        'avatar_url': null,
        'average_rating': null,
        'total_ratings': 0,
        'vehicles': [],
      };
      final d = AvailableDriver.fromMap(row);
      expect(d.avatarUrl, null);
      expect(d.averageRating, null);
      expect(d.vehicle, null);
    });

    test('vehicles vazio → vehicle null', () {
      final row = {
        'driver_profile_id': 'd1',
        'full_name': 'Ana',
        'avatar_url': null,
        'average_rating': null,
        'total_ratings': 0,
        'vehicles': [],
      };
      expect(AvailableDriver.fromMap(row).vehicle, null);
    });

    test('múltiplos vehicles → escolhe is_active=true', () {
      final row = {
        'driver_profile_id': 'd1',
        'full_name': 'N',
        'avatar_url': null,
        'average_rating': null,
        'total_ratings': 0,
        'vehicles': [
          {'brand': 'A', 'model': '1', 'color': '-', 'license_plate': 'A', 'is_active': false},
          {'brand': 'B', 'model': '2', 'color': '-', 'license_plate': 'B', 'is_active': true},
        ],
      };
      expect(AvailableDriver.fromMap(row).vehicle?.brand, 'B');
    });
  });
}
