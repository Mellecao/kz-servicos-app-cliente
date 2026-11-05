import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

void main() {
  group('TripPassengerData', () {
    test('identifies passengers aged 10 or younger as needing a car seat', () {
      expect(
        const TripPassengerData(name: 'Ana', age: 10).needsCarSeat,
        isTrue,
      );
      expect(
        const TripPassengerData(name: 'Bia', age: 11).needsCarSeat,
        isFalse,
      );
    });

    test('rejects ages outside the database range', () {
      expect(
        () => TripPassengerData(name: 'Ana', age: -1),
        throwsAssertionError,
      );
      expect(
        () => TripPassengerData(name: 'Ana', age: 121),
        throwsAssertionError,
      );
    });

    test('uses value equality', () {
      expect(
        const TripPassengerData(name: 'Ana', age: 8),
        const TripPassengerData(name: 'Ana', age: 8),
      );
    });
  });

  group('TripLuggageData', () {
    test('stores optional weight and defaults quantity to one', () {
      const luggage = TripLuggageData(
        type: 'suitcase',
        size: 'medium',
        weightKg: 12.5,
      );

      expect(luggage.weightKg, 12.5);
      expect(luggage.quantity, 1);
    });

    test('uses value equality', () {
      expect(
        const TripLuggageData(type: 'backpack', size: 'small'),
        const TripLuggageData(type: 'backpack', size: 'small'),
      );
    });
  });
}
