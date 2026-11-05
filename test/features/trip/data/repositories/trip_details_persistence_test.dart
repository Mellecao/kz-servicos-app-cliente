import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/repositories/trip_details_persistence.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

void main() {
  test(
    'persists passenger and luggage rows after a trip id is available',
    () async {
      final writes = <({String table, List<Map<String, dynamic>> rows})>[];
      final persistence = TripDetailsPersistence(
        insertRows: (table, rows) async =>
            writes.add((table: table, rows: rows)),
      );

      await persistence.persist(
        tripId: 'trip-1',
        passengers: const [TripPassengerData(name: 'Ana', age: 10)],
        luggage: const [
          TripLuggageData(type: 'suitcase', size: 'medium', weightKg: 15),
        ],
      );

      expect(writes.map((write) => write.table), [
        'trip_passengers',
        'trip_luggage',
      ]);
      expect(writes.first.rows.single, {
        'trip_id': 'trip-1',
        'name': 'Ana',
        'age': 10,
        'sort_order': 0,
      });
      expect(writes.last.rows.single['weight_kg'], 15);
    },
  );

  test('does not issue empty inserts for legacy requests', () async {
    var writes = 0;
    final persistence = TripDetailsPersistence(
      insertRows: (_, _) async => writes++,
    );

    await persistence.persist(
      tripId: 'trip-1',
      passengers: const [],
      luggage: const [],
    );

    expect(writes, 0);
  });
}
