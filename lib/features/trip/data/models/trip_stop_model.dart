class TripStopModel {
  static List<Map<String, dynamic>> buildInsertJsonList({
    required String tripId,
    required List<String> addressIds,
  }) {
    return [
      for (var i = 0; i < addressIds.length; i++)
        {'trip_id': tripId, 'address_id': addressIds[i], 'stop_order': i + 1},
    ];
  }
}
