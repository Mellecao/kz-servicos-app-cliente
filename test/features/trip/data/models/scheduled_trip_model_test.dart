import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/scheduled_trip_model.dart';

void main() {
  group('ScheduledTripModel', () {
    test('fromJson parses trip with full address data', () {
      final json = {
        'id': 'trip-1',
        'status': 'scheduled',
        'scheduled_datetime': '2026-04-20T10:00:00Z',
        'passenger_count': 2,
        'observations': 'Ida ao aeroporto',
        'pickup_address': {
          'id': 'addr-1',
          'formatted_address': 'Rua Augusta, 100 - Consolação, SP',
          'street': 'Rua Augusta',
          'number': '100',
          'neighborhood': 'Consolação',
          'city': 'São Paulo',
          'state': 'SP',
          'latitude': -23.5534,
          'longitude': -46.658,
        },
        'dropoff_address': {
          'id': 'addr-2',
          'formatted_address': 'Aeroporto de Guarulhos, Guarulhos - SP',
          'street': 'Rod. Hélio Smidt',
          'number': 's/n',
          'neighborhood': 'Cumbica',
          'city': 'Guarulhos',
          'state': 'SP',
          'latitude': -23.4356,
          'longitude': -46.4731,
        },
        'driver_profiles': null,
      };

      final model = ScheduledTripModel.fromJson(json);

      expect(model.id, 'trip-1');
      expect(model.status, 'scheduled');
      expect(model.origin, 'Rua Augusta, 100 - Consolação');
      expect(model.destination, 'Rod. Hélio Smidt, s/n - Cumbica');
      expect(model.originLat, -23.5534);
      expect(model.originLng, -46.658);
      expect(model.destinationLat, -23.4356);
      expect(model.destinationLng, -46.4731);
      expect(model.passengerCount, 2);
      expect(model.driverName, isNull);
      expect(model.observations, 'Ida ao aeroporto');
    });

    test('fromJson extracts driverName from nested relations', () {
      final json = {
        'id': 'trip-2',
        'status': 'open',
        'scheduled_datetime': '2026-04-22T14:00:00Z',
        'passenger_count': 1,
        'pickup_address': {
          'formatted_address': 'Av. Paulista, 1000',
          'street': 'Av. Paulista',
          'number': '1000',
          'latitude': '-23.5613',
          'longitude': '-46.6565',
        },
        'dropoff_address': {
          'formatted_address': 'Shopping Eldorado',
          'latitude': -23.5727,
          'longitude': -46.6951,
        },
        'driver_profiles': {
          'provider_profiles': {
            'users': {'full_name': 'João Silva'},
          },
        },
      };

      final model = ScheduledTripModel.fromJson(json);

      expect(model.driverName, 'João Silva');
      expect(model.origin, 'Av. Paulista, 1000');
      expect(model.destination, 'Shopping Eldorado');
    });

    test('fromJson handles null addresses gracefully', () {
      final json = {
        'id': 'trip-3',
        'status': 'open',
        'scheduled_datetime': '2026-04-25T09:00:00Z',
        'passenger_count': 1,
        'pickup_address': null,
        'dropoff_address': null,
      };

      final model = ScheduledTripModel.fromJson(json);

      expect(model.origin, 'Endereço desconhecido');
      expect(model.destination, 'Endereço desconhecido');
      expect(model.originLat, 0.0);
      expect(model.originLng, 0.0);
    });

    test('fromJson uses formatted_address when street is missing', () {
      final json = {
        'id': 'trip-4',
        'status': 'scheduled',
        'scheduled_datetime': '2026-04-28T12:00:00Z',
        'passenger_count': 3,
        'pickup_address': {
          'formatted_address': 'Rodoviária Tietê',
          'latitude': -23.5153,
          'longitude': -46.6250,
        },
        'dropoff_address': {
          'formatted_address': 'Aeroporto de Congonhas',
          'street': 'R. do Aeroporto',
          'latitude': -23.6264,
          'longitude': -46.6566,
        },
      };

      final model = ScheduledTripModel.fromJson(json);

      expect(model.origin, 'Rodoviária Tietê');
      expect(model.destination, 'R. do Aeroporto');
    });

    test('toEntity converts to ScheduledTrip domain entity', () {
      final json = {
        'id': 'trip-5',
        'status': 'scheduled',
        'scheduled_datetime': '2026-05-01T16:00:00Z',
        'passenger_count': 4,
        'pickup_address': {
          'formatted_address': 'Origin',
          'latitude': -23.55,
          'longitude': -46.63,
        },
        'dropoff_address': {
          'formatted_address': 'Dest',
          'latitude': -23.57,
          'longitude': -46.69,
        },
      };

      final entity = ScheduledTripModel.fromJson(json).toEntity();

      expect(entity.id, 'trip-5');
      expect(entity.status, 'scheduled');
      expect(entity.passengerCount, 4);
      expect(entity.scheduledDatetime.year, 2026);
    });

    test('_toDouble handles string, int, and double inputs', () {
      final json = {
        'id': 'trip-6',
        'status': 'open',
        'scheduled_datetime': '2026-05-02T10:00:00Z',
        'passenger_count': 1,
        'pickup_address': {
          'formatted_address': 'A',
          'latitude': '-23.55',
          'longitude': -46,
        },
        'dropoff_address': {
          'formatted_address': 'B',
          'latitude': 1.5,
          'longitude': '2.5',
        },
      };

      final model = ScheduledTripModel.fromJson(json);

      expect(model.originLat, -23.55);
      expect(model.originLng, -46.0);
      expect(model.destinationLat, 1.5);
      expect(model.destinationLng, 2.5);
    });
  });
}
