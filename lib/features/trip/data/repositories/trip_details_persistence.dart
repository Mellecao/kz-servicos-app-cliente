import 'package:kz_servicos_app/features/trip/data/models/trip_luggage_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_passenger_model.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

typedef InsertTripDetailRows =
    Future<void> Function(String table, List<Map<String, dynamic>> rows);

class TripDetailsPersistence {
  const TripDetailsPersistence({required InsertTripDetailRows insertRows})
    : _insertRows = insertRows;

  final InsertTripDetailRows _insertRows;

  Future<void> persist({
    required String tripId,
    required List<TripPassengerData> passengers,
    required List<TripLuggageData> luggage,
  }) async {
    if (passengers.isNotEmpty) {
      await _insertRows(
        'trip_passengers',
        TripPassengerModel.buildInsertJsonList(
          tripId: tripId,
          passengers: passengers,
        ),
      );
    }

    if (luggage.isNotEmpty) {
      await _insertRows(
        'trip_luggage',
        TripLuggageModel.buildInsertJsonList(tripId: tripId, luggage: luggage),
      );
    }
  }
}
