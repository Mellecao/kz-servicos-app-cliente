import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';

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
    this.paymentMethod = 'pix',
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
  ];
}
