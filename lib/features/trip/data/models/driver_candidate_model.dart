import 'package:kz_servicos_app/features/trip/domain/entities/driver_candidate.dart';

class DriverCandidateModel {
  const DriverCandidateModel({
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

  factory DriverCandidateModel.fromJson(Map<String, dynamic> json) {
    final driverProfile = json['driver_profiles'] as Map<String, dynamic>?;
    final providerProfile =
        driverProfile?['provider_profiles'] as Map<String, dynamic>?;
    final user = providerProfile?['users'] as Map<String, dynamic>?;

    final vehicles = driverProfile?['vehicles'] as List<dynamic>?;
    Map<String, dynamic>? vehicle;
    if (vehicles != null && vehicles.isNotEmpty) {
      vehicle = vehicles.cast<Map<String, dynamic>>().firstWhere(
            (v) => v['is_active'] == true,
            orElse: () => vehicles.first as Map<String, dynamic>,
          );
    }

    return DriverCandidateModel(
      candidateId: json['id'] as String,
      tripId: json['trip_id'] as String,
      driverProfileId: json['driver_profile_id'] as String,
      driverName: (user?['full_name'] as String?) ?? 'Motorista',
      avatarUrl: user?['avatar_url'] as String?,
      vehicleId: vehicle?['id'] as String?,
      vehicleBrand: vehicle?['brand'] as String?,
      vehicleModel: vehicle?['model'] as String?,
      vehicleYear: vehicle?['year'] as int?,
      vehicleColor: vehicle?['color'] as String?,
      vehiclePlate: vehicle?['license_plate'] as String?,
    );
  }

  DriverCandidate toEntity() => DriverCandidate(
        candidateId: candidateId,
        tripId: tripId,
        driverProfileId: driverProfileId,
        driverName: driverName,
        avatarUrl: avatarUrl,
        vehicleId: vehicleId,
        vehicleBrand: vehicleBrand,
        vehicleModel: vehicleModel,
        vehicleYear: vehicleYear,
        vehicleColor: vehicleColor,
        vehiclePlate: vehiclePlate,
      );
}
