import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_luggage_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_passenger_model.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

void main() {
  test('TripPassengerModel builds ordered rows without generated columns', () {
    final rows = TripPassengerModel.buildInsertJsonList(
      tripId: 'trip-1',
      passengers: const [
        TripPassengerData(name: 'Ana', age: 7),
        TripPassengerData(name: 'Bruno', age: 42),
      ],
    );

    expect(rows, [
      {'trip_id': 'trip-1', 'name': 'Ana', 'age': 7, 'sort_order': 0},
      {'trip_id': 'trip-1', 'name': 'Bruno', 'age': 42, 'sort_order': 1},
    ]);
    expect(rows.first, isNot(contains('needs_car_seat')));
  });

  test('TripLuggageModel builds detailed ordered rows', () {
    final rows = TripLuggageModel.buildInsertJsonList(
      tripId: 'trip-1',
      luggage: const [
        TripLuggageData(
          type: 'suitcase',
          size: 'large',
          weightKg: 20.5,
          quantity: 2,
        ),
        TripLuggageData(type: 'backpack', size: 'small'),
      ],
    );

    expect(rows, [
      {
        'trip_id': 'trip-1',
        'type': 'suitcase',
        'size': 'large',
        'weight_kg': 20.5,
        'quantity': 2,
        'sort_order': 0,
      },
      {
        'trip_id': 'trip-1',
        'type': 'backpack',
        'size': 'small',
        'quantity': 1,
        'sort_order': 1,
      },
    ]);
  });
}
