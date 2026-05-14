import 'package:equatable/equatable.dart';

/// A driver who has expressed interest in taking a specific trip.
/// Loaded from `trip_driver_candidates` joined with the driver's profile,
/// user data and (optionally) one of their vehicles.
class DriverCandidate extends Equatable {
  const DriverCandidate({
    required this.candidateId,
    required this.tripId,
    required this.driverProfileId,
    required this.driverName,
    this.avatarUrl,
    this.vehicleId,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleColor,
    this.vehiclePlate,
  });

  final String candidateId;
  final String tripId;
  final String driverProfileId;
  final String driverName;
  final String? avatarUrl;

  final String? vehicleId;
  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehicleColor;
  final String? vehiclePlate;

  String? get vehicleSummary {
    if (vehicleBrand == null && vehicleModel == null) return null;
    final parts = <String>[
      ?vehicleBrand,
      ?vehicleModel,
      ?vehicleYear?.toString(),
    ];
    return parts.join(' ');
  }

  String get initials {
    final parts =
        driverName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0].toUpperCase();
    if (parts.length == 1) return first;
    final last = parts.last[0].toUpperCase();
    return '$first$last';
  }

  @override
  List<Object?> get props => [candidateId, tripId, driverProfileId];
}
