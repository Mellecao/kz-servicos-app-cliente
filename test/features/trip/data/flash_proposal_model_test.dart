import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/flash_proposal_model.dart';

void main() {
  group('FlashProposalModel.fromJson', () {
    test('parses candidate + driver join payload', () {
      final json = {
        'id': 'cand-1',
        'trip_id': 'trip-1',
        'driver_profile_id': 'drv-1',
        'offered_price': '55.00',
        'created_at': '2026-07-29T12:00:00Z',
        'driver_profiles': {
          'photo_url': 'https://x/y.png',
          'provider_profiles': {
            'user': {'name': 'João Silva'}
          },
          'vehicles': [
            {'brand': 'Chevrolet', 'model': 'Onix', 'color': 'Prata'}
          ],
        },
      };
      final m = FlashProposalModel.fromJson(json);
      expect(m.candidateId, 'cand-1');
      expect(m.tripId, 'trip-1');
      expect(m.driverProfileId, 'drv-1');
      expect(m.offeredPrice, 55.0);
      expect(m.driverName, 'João Silva');
      expect(m.driverPhotoUrl, 'https://x/y.png');
      expect(m.vehicleLabel, contains('Onix'));
      expect(m.vehicleLabel, contains('Prata'));
    });

    test('handles missing driver joins gracefully', () {
      final json = {
        'id': 'cand-2',
        'trip_id': 'trip-2',
        'driver_profile_id': 'drv-2',
        'offered_price': 40,
        'created_at': '2026-07-29T13:00:00Z',
      };
      final m = FlashProposalModel.fromJson(json);
      expect(m.driverName, 'Motorista');
      expect(m.driverPhotoUrl, isNull);
      expect(m.vehicleLabel, '');
      expect(m.offeredPrice, 40.0);
    });

    test('toEntity carries injected metrics', () {
      final json = {
        'id': 'c',
        'trip_id': 't',
        'driver_profile_id': 'd',
        'offered_price': '10',
        'created_at': '2026-07-29T12:00:00Z',
      };
      final e = FlashProposalModel.fromJson(json)
          .toEntity(etaMinutes: 12.5, driverRatingAvg: 4.7, driverFinishedTrips: 42);
      expect(e.etaMinutes, 12.5);
      expect(e.driverRatingAvg, 4.7);
      expect(e.driverFinishedTrips, 42);
    });
  });
}
