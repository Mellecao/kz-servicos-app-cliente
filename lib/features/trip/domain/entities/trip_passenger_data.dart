import 'package:equatable/equatable.dart';

/// Immutable passenger details persisted for a trip.
class TripPassengerData extends Equatable {
  const TripPassengerData({required this.name, required this.age})
    : assert(name != '', 'Passenger name must not be empty'),
      assert(age >= 0 && age <= 120, 'Passenger age must be between 0 and 120');

  final String name;
  final int age;

  bool get needsCarSeat => age <= 10;

  @override
  List<Object?> get props => [name, age];
}
