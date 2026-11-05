import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_stop_model.dart';

void main() {
  group('TripStopModel.buildInsertJsonList', () {
    test('builds one row per address id with 1-indexed stop_order', () {
      final rows = TripStopModel.buildInsertJsonList(
        tripId: 'trip-uuid',
        addressIds: ['addr-1', 'addr-2', 'addr-3'],
      );

      expect(rows, [
        {'trip_id': 'trip-uuid', 'address_id': 'addr-1', 'stop_order': 1},
        {'trip_id': 'trip-uuid', 'address_id': 'addr-2', 'stop_order': 2},
        {'trip_id': 'trip-uuid', 'address_id': 'addr-3', 'stop_order': 3},
      ]);
    });

    test('returns an empty list when there are no stops', () {
      final rows = TripStopModel.buildInsertJsonList(
        tripId: 'trip-uuid',
        addressIds: const [],
      );

      expect(rows, isEmpty);
    });
  });
}
