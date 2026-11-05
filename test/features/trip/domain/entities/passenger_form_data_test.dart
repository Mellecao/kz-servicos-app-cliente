import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/passenger_form_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

void main() {
  group('PassengerFormData.copyWith', () {
    test('overrides only the given fields', () {
      final original = PassengerFormData(
        adults: 2,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        hasChildren: true,
        childrenDescription: '1 criança',
        hasLuggage: true,
        luggageDescription: '1 mala',
        observations: 'Portão azul',
        paymentMethod: 'pix',
        isRoundTrip: true,
        returnDatetime: DateTime(2026, 8, 16, 18, 0),
      );

      final updated = original.copyWith(paymentMethod: 'credit');

      expect(updated.paymentMethod, 'credit');
      expect(updated.adults, 2);
      expect(updated.scheduledDatetime, DateTime(2026, 8, 16, 10, 0));
      expect(updated.hasChildren, isTrue);
      expect(updated.childrenDescription, '1 criança');
      expect(updated.hasLuggage, isTrue);
      expect(updated.luggageDescription, '1 mala');
      expect(updated.observations, 'Portão azul');
      expect(updated.isRoundTrip, isTrue);
      expect(updated.returnDatetime, DateTime(2026, 8, 16, 18, 0));
    });

    test('keeps original values when no override is given', () {
      final original = PassengerFormData(
        adults: 1,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
      );

      final copy = original.copyWith();

      expect(copy.adults, original.adults);
      expect(copy.scheduledDatetime, original.scheduledDatetime);
      expect(copy.paymentMethod, original.paymentMethod);
    });

    test('preserves detailed passengers and luggage', () {
      final original = PassengerFormData(
        adults: 1,
        scheduledDatetime: DateTime(2026, 8, 16, 10),
        passengers: const [TripPassengerData(name: 'Ana', age: 8)],
        luggage: const [
          TripLuggageData(type: 'suitcase', size: 'medium', weightKg: 12),
        ],
      );

      final copy = original.copyWith(paymentMethod: 'credit');

      expect(copy.passengers, original.passengers);
      expect(copy.luggage, original.luggage);
    });
  });
}
