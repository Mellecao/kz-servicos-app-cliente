import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

class TripPassengerModel extends Equatable {
  const TripPassengerModel({required this.name, required this.age});

  factory TripPassengerModel.fromEntity(TripPassengerData passenger) =>
      TripPassengerModel(name: passenger.name, age: passenger.age);

  final String name;
  final int age;

  Map<String, dynamic> toInsertJson({
    required String tripId,
    required int sortOrder,
  }) => {'trip_id': tripId, 'name': name, 'age': age, 'sort_order': sortOrder};

  static List<Map<String, dynamic>> buildInsertJsonList({
    required String tripId,
    required List<TripPassengerData> passengers,
  }) => [
    for (var index = 0; index < passengers.length; index++)
      TripPassengerModel.fromEntity(
        passengers[index],
      ).toInsertJson(tripId: tripId, sortOrder: index),
  ];

  @override
  List<Object?> get props => [name, age];
}
