import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';

class ScheduledTripModel {
  const ScheduledTripModel({
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

  factory ScheduledTripModel.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickup_address'] as Map<String, dynamic>?;
    final dropoff = json['dropoff_address'] as Map<String, dynamic>?;

    final driverProfile =
        json['driver_profiles'] as Map<String, dynamic>?;
    final providerProfile =
        driverProfile?['provider_profiles'] as Map<String, dynamic>?;
    final driverUser =
        providerProfile?['users'] as Map<String, dynamic>?;

    return ScheduledTripModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'open',
      scheduledDatetime:
          DateTime.parse(json['scheduled_datetime'] as String),
      origin: _buildShortAddress(pickup),
      destination: _buildShortAddress(dropoff),
      originLat: _toDouble(pickup?['latitude']),
      originLng: _toDouble(pickup?['longitude']),
      destinationLat: _toDouble(dropoff?['latitude']),
      destinationLng: _toDouble(dropoff?['longitude']),
      passengerCount: json['passenger_count'] as int? ?? 1,
      driverName: driverUser?['full_name'] as String?,
      observations: json['observations'] as String?,
    );
  }

  static String _buildShortAddress(Map<String, dynamic>? addr) {
    if (addr == null) return 'Endereço desconhecido';

    final street = addr['street'] as String?;
    final number = addr['number'] as String?;
    final neighborhood = addr['neighborhood'] as String?;

    if (street != null && number != null && neighborhood != null) {
      return '$street, $number - $neighborhood';
    }
    if (street != null && number != null) {
      return '$street, $number';
    }
    if (street != null) return street;

    return addr['formatted_address'] as String? ??
        'Endereço desconhecido';
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  ScheduledTrip toEntity() => ScheduledTrip(
        id: id,
        status: status,
        scheduledDatetime: scheduledDatetime,
        origin: origin,
        destination: destination,
        originLat: originLat,
        originLng: originLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        passengerCount: passengerCount,
        driverName: driverName,
        observations: observations,
      );
}
