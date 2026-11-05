import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

class TripRequest extends Equatable {
  const TripRequest({
    required this.clientId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.scheduledDatetime,
    required this.passengerCount,
    this.childrenCount = 0,
    this.childrenDescription,
    this.luggageCount = 0,
    this.luggageDescription,
    this.observations,
    this.paymentMethod = 'cash',
    this.isRoundTrip = false,
    this.returnDatetime,
    this.returnPickupAddress,
    this.returnDropoffAddress,
    this.tripType = 'standard',
    this.stops = const [],
    this.passengers = const [],
    this.luggage = const [],
  });

  final String clientId;
  final TripAddress pickupAddress;
  final TripAddress dropoffAddress;
  final DateTime scheduledDatetime;
  final int passengerCount;
  final int childrenCount;
  final String? childrenDescription;
  final int luggageCount;
  final String? luggageDescription;
  final String? observations;
  final String paymentMethod;
  final bool isRoundTrip;
  final DateTime? returnDatetime;
  final TripAddress? returnPickupAddress;
  final TripAddress? returnDropoffAddress;
  final String tripType;
  final List<TripAddress> stops;
  final List<TripPassengerData> passengers;
  final List<TripLuggageData> luggage;

  int get aggregatePassengerCount =>
      passengers.isEmpty ? passengerCount : passengers.length;

  int get aggregateChildrenCount => passengers.isEmpty
      ? childrenCount
      : passengers.where((passenger) => passenger.needsCarSeat).length;

  int get aggregateLuggageCount => luggage.isEmpty
      ? luggageCount
      : luggage.fold(0, (total, item) => total + item.quantity);

  /// Builds the combined observations field from form data.
  String? get combinedObservations {
    final parts = <String>[];
    if (childrenDescription != null && childrenDescription!.isNotEmpty) {
      parts.add('Crianças: $childrenDescription');
    }
    if (luggageDescription != null && luggageDescription!.isNotEmpty) {
      parts.add('Bagagem: $luggageDescription');
    }
    if (observations != null && observations!.isNotEmpty) {
      parts.add(observations!);
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  @override
  List<Object?> get props => [
    clientId,
    pickupAddress,
    dropoffAddress,
    scheduledDatetime,
    passengerCount,
    isRoundTrip,
    returnDatetime,
    returnPickupAddress,
    returnDropoffAddress,
    tripType,
    stops,
    passengers,
    luggage,
  ];
}
