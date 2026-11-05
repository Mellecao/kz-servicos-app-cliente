import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';

void main() {
  group('TripRequest.stops', () {
    const pickup = TripAddress(
      formattedAddress: 'Rua A, São Paulo - SP',
      city: 'São Paulo',
      state: 'SP',
      latitude: -23.55,
      longitude: -46.63,
    );
    const dropoff = TripAddress(
      formattedAddress: 'Rua B, São Paulo - SP',
      city: 'São Paulo',
      state: 'SP',
      latitude: -23.56,
      longitude: -46.64,
    );

    test('defaults to an empty list when not provided', () {
      final request = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        passengerCount: 1,
      );

      expect(request.stops, isEmpty);
    });

    test('stores the given stops in order', () {
      const stop1 = TripAddress(
        formattedAddress: 'Rua C, São Paulo - SP',
        city: 'São Paulo',
        state: 'SP',
        latitude: -23.57,
        longitude: -46.65,
      );
      const stop2 = TripAddress(
        formattedAddress: 'Rua D, São Paulo - SP',
        city: 'São Paulo',
        state: 'SP',
        latitude: -23.58,
        longitude: -46.66,
      );

      final request = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        passengerCount: 1,
        stops: const [stop1, stop2],
      );

      expect(request.stops, [stop1, stop2]);
    });

    test('two requests with different stops are not equal', () {
      const stop = TripAddress(
        formattedAddress: 'Rua C, São Paulo - SP',
        city: 'São Paulo',
        state: 'SP',
        latitude: -23.57,
        longitude: -46.65,
      );

      final withStop = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        passengerCount: 1,
        stops: const [stop],
      );
      final withoutStop = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        passengerCount: 1,
      );

      expect(withStop, isNot(equals(withoutStop)));
    });
  });

  group('TripRequest detailed aggregates', () {
    const pickup = TripAddress(
      formattedAddress: 'Rua A, São Paulo - SP',
      city: 'São Paulo',
      state: 'SP',
      latitude: -23.55,
      longitude: -46.63,
    );
    const dropoff = TripAddress(
      formattedAddress: 'Rua B, São Paulo - SP',
      city: 'São Paulo',
      state: 'SP',
      latitude: -23.56,
      longitude: -46.64,
    );

    test('derives counts from detailed lists when they are provided', () {
      final request = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10),
        passengerCount: 99,
        childrenCount: 99,
        luggageCount: 99,
        passengers: const [
          TripPassengerData(name: 'Ana', age: 10),
          TripPassengerData(name: 'Bruno', age: 11),
        ],
        luggage: const [
          TripLuggageData(type: 'suitcase', size: 'large', quantity: 2),
          TripLuggageData(type: 'backpack', size: 'small'),
        ],
      );

      expect(request.aggregatePassengerCount, 2);
      expect(request.aggregateChildrenCount, 1);
      expect(request.aggregateLuggageCount, 3);
    });

    test('keeps legacy counts when detailed lists are absent', () {
      final request = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10),
        passengerCount: 3,
        childrenCount: 1,
        luggageCount: 2,
      );

      expect(request.aggregatePassengerCount, 3);
      expect(request.aggregateChildrenCount, 1);
      expect(request.aggregateLuggageCount, 2);
    });
  });
}
