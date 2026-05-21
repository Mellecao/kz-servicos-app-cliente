import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/driver_candidate_model.dart';

void main() {
  group('DriverCandidateModel', () {
    final baseJson = {
      'id': 'cand-1',
      'trip_id': 'trip-1',
      'driver_profile_id': 'driver-1',
      'driver_profiles': {
        'id': 'driver-1',
        'provider_profiles': {
          'users': {'full_name': 'Joao Silva', 'avatar_url': null},
        },
        'vehicles': [],
      },
    };

    test('parses offered_price when present', () {
      final json = {...baseJson, 'offered_price': 150.50};
      final model = DriverCandidateModel.fromJson(json);
      expect(model.offeredPrice, 150.50);
    });

    test('handles null offered_price', () {
      final json = {...baseJson, 'offered_price': null};
      final model = DriverCandidateModel.fromJson(json);
      expect(model.offeredPrice, isNull);
    });

    test('maps offeredPrice to entity', () {
      final json = {...baseJson, 'offered_price': 200.0};
      final entity = DriverCandidateModel.fromJson(json).toEntity();
      expect(entity.offeredPrice, 200.0);
    });

    test('entity with null offeredPrice maps correctly', () {
      final model = DriverCandidateModel.fromJson(baseJson);
      final entity = model.toEntity();
      expect(entity.offeredPrice, isNull);
    });
  });
}
