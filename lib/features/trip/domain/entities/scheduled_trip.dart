import 'package:equatable/equatable.dart';

/// Represents a scheduled trip with display-ready fields.
class ScheduledTrip extends Equatable {
  const ScheduledTrip({
    required this.id,
    required this.status,
    required this.scheduledDatetime,
    required this.origin,
    required this.destination,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.passengerCount,
    this.driverName,
    this.observations,
  });

  final String id;
  final String status;
  final DateTime scheduledDatetime;
  final String origin;
  final String destination;
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final int passengerCount;
  final String? driverName;
  final String? observations;

  @override
  List<Object?> get props => [id, status, scheduledDatetime];
}
