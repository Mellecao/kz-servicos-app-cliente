import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';

class TripLuggageModel extends Equatable {
  const TripLuggageModel({
    required this.type,
    required this.size,
    required this.quantity,
    this.weightKg,
  });

  factory TripLuggageModel.fromEntity(TripLuggageData luggage) =>
      TripLuggageModel(
        type: luggage.type,
        size: luggage.size,
        weightKg: luggage.weightKg,
        quantity: luggage.quantity,
      );

  final String type;
  final String size;
  final double? weightKg;
  final int quantity;

  Map<String, dynamic> toInsertJson({
    required String tripId,
    required int sortOrder,
  }) => {
    'trip_id': tripId,
    'type': type,
    'size': size,
    if (weightKg != null) 'weight_kg': weightKg,
    'quantity': quantity,
    'sort_order': sortOrder,
  };

  static List<Map<String, dynamic>> buildInsertJsonList({
    required String tripId,
    required List<TripLuggageData> luggage,
  }) => [
    for (var index = 0; index < luggage.length; index++)
      TripLuggageModel.fromEntity(
        luggage[index],
      ).toInsertJson(tripId: tripId, sortOrder: index),
  ];

  @override
  List<Object?> get props => [type, size, weightKg, quantity];
}
