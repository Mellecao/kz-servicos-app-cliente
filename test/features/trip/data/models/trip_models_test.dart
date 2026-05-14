import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/address_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_model.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';

void main() {
  group('AddressModel', () {
    test('toJson produces correct map', () {
      const model = AddressModel(
        googlePlaceId: 'place_abc',
        formattedAddress: 'Rua A, 100 - Centro, São Paulo - SP',
        street: 'Rua A',
        number: '100',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
        latitude: -23.5505,
        longitude: -46.6333,
      );

      final json = model.toJson();

      expect(json['google_place_id'], 'place_abc');
      expect(json['formatted_address'], 'Rua A, 100 - Centro, São Paulo - SP');
      expect(json['street'], 'Rua A');
      expect(json['number'], '100');
      expect(json['neighborhood'], 'Centro');
      expect(json['city'], 'São Paulo');
      expect(json['state'], 'SP');
      expect(json['zip_code'], '01001-000');
      expect(json['latitude'], -23.5505);
      expect(json['longitude'], -46.6333);
    });

    test('toJson omits null optional fields', () {
      const model = AddressModel(
        formattedAddress: 'Rua A, São Paulo - SP',
        city: 'São Paulo',
        state: 'SP',
        latitude: -23.55,
        longitude: -46.63,
      );

      final json = model.toJson();

      expect(json.containsKey('google_place_id'), isFalse);
      expect(json.containsKey('street'), isFalse);
      expect(json.containsKey('number'), isFalse);
      expect(json.containsKey('zip_code'), isFalse);
      expect(json['formatted_address'], 'Rua A, São Paulo - SP');
    });

    test('fromJson parses all fields', () {
      final json = {
        'id': 'addr-uuid',
        'google_place_id': 'place_abc',
        'formatted_address': 'Rua A, 100 - Centro, São Paulo - SP',
        'street': 'Rua A',
        'number': '100',
        'neighborhood': 'Centro',
        'city': 'São Paulo',
        'state': 'SP',
        'zip_code': '01001-000',
        'latitude': -23.5505,
        'longitude': -46.6333,
      };

      final model = AddressModel.fromJson(json);

      expect(model.id, 'addr-uuid');
      expect(model.googlePlaceId, 'place_abc');
      expect(model.city, 'São Paulo');
      expect(model.latitude, -23.5505);
    });

    test('fromEntity converts TripAddress correctly', () {
      const entity = TripAddress(
        googlePlaceId: 'place_abc',
        formattedAddress: 'Rua A, São Paulo - SP',
        city: 'São Paulo',
        state: 'SP',
        latitude: -23.55,
        longitude: -46.63,
      );

      final model = AddressModel.fromEntity(entity);

      expect(model.googlePlaceId, 'place_abc');
      expect(model.formattedAddress, 'Rua A, São Paulo - SP');
      expect(model.city, 'São Paulo');
    });
  });

  group('TripModel', () {
    test('buildInsertJson produces correct map', () {
      final json = TripModel.buildInsertJson(
        clientId: 'user-uuid',
        serviceCategoryId: 'cat-uuid',
        pickupAddressId: 'addr-pickup',
        dropoffAddressId: 'addr-dropoff',
        scheduledDatetime: DateTime.utc(2026, 4, 20, 14, 30),
        passengerCount: 2,
        childrenCount: 1,
        luggageCount: 3,
        observations: 'Test obs',
        paymentMethod: 'pix',
      );

      expect(json['client_id'], 'user-uuid');
      expect(json['service_category_id'], 'cat-uuid');
      expect(json['pickup_address_id'], 'addr-pickup');
      expect(json['dropoff_address_id'], 'addr-dropoff');
      expect(json['scheduled_datetime'], '2026-04-20T14:30:00.000Z');
      expect(json['passenger_count'], 2);
      expect(json['children_count'], 1);
      expect(json['luggage_count'], 3);
      expect(json['observations'], 'Test obs');
      expect(json['payment_method'], 'pix');
    });

    test('buildInsertJson omits null observations and payment_method', () {
      final json = TripModel.buildInsertJson(
        clientId: 'user-uuid',
        serviceCategoryId: 'cat-uuid',
        pickupAddressId: 'addr-pickup',
        dropoffAddressId: 'addr-dropoff',
        scheduledDatetime: DateTime.utc(2026, 4, 20, 14, 30),
        passengerCount: 1,
      );

      expect(json.containsKey('observations'), isFalse);
      expect(json.containsKey('payment_method'), isFalse);
    });

    test('fromJson parses trip response', () {
      final json = {
        'id': 'trip-uuid',
        'client_id': 'user-uuid',
        'service_category_id': 'cat-uuid',
        'pickup_address_id': 'addr-1',
        'dropoff_address_id': 'addr-2',
        'scheduled_datetime': '2026-04-20T14:30:00.000Z',
        'passenger_count': 2,
        'children_count': 1,
        'luggage_count': 0,
        'observations': 'Obs',
        'payment_method': 'pix',
        'status': 'open',
        'created_at': '2026-04-18T10:00:00.000Z',
      };

      final model = TripModel.fromJson(json);

      expect(model.id, 'trip-uuid');
      expect(model.clientId, 'user-uuid');
      expect(model.passengerCount, 2);
      expect(model.status, 'open');
      expect(model.scheduledDatetime, DateTime.utc(2026, 4, 20, 14, 30));
    });

    test('toEntity converts to Trip correctly', () {
      final model = TripModel(
        id: 'trip-uuid',
        clientId: 'user-uuid',
        serviceCategoryId: 'cat-uuid',
        pickupAddressId: 'addr-1',
        dropoffAddressId: 'addr-2',
        scheduledDatetime: DateTime.utc(2026, 4, 20, 14, 30),
        passengerCount: 3,
        status: 'open',
        observations: 'Test',
        createdAt: DateTime.utc(2026, 4, 18),
      );

      final entity = model.toEntity();

      expect(entity.id, 'trip-uuid');
      expect(entity.clientId, 'user-uuid');
      expect(entity.status, 'open');
      expect(entity.passengerCount, 3);
      expect(entity.observations, 'Test');
    });
  });
}
