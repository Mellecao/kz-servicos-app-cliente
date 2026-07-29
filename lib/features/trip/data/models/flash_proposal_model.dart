import '../../domain/entities/flash_proposal.dart';

class FlashProposalModel {
  final String candidateId;
  final String tripId;
  final String driverProfileId;
  final String driverName;
  final String? driverPhotoUrl;
  final String vehicleLabel;
  final double offeredPrice;
  final DateTime createdAt;

  FlashProposalModel({
    required this.candidateId,
    required this.tripId,
    required this.driverProfileId,
    required this.driverName,
    required this.driverPhotoUrl,
    required this.vehicleLabel,
    required this.offeredPrice,
    required this.createdAt,
  });

  factory FlashProposalModel.fromJson(Map<String, dynamic> json) {
    final driver = (json['driver_profiles'] as Map?) ?? const {};
    final provider = (driver['provider_profiles'] as Map?) ?? const {};
    final user = (provider['user'] as Map?) ?? const {};
    final vehiclesRaw = driver['vehicles'];
    final vehicles = vehiclesRaw is List ? vehiclesRaw : const [];
    final v = vehicles.isNotEmpty ? vehicles.first as Map : const {};
    final brand = (v['brand'] as String?) ?? '';
    final model = (v['model'] as String?) ?? '';
    final color = (v['color'] as String?) ?? '';
    final vehicleLabel = [brand, model, color]
        .where((p) => p.isNotEmpty)
        .join(' ')
        .trim();
    return FlashProposalModel(
      candidateId: json['id'] as String,
      tripId: json['trip_id'] as String,
      driverProfileId: json['driver_profile_id'] as String,
      driverName: (user['name'] as String?) ?? 'Motorista',
      driverPhotoUrl: driver['photo_url'] as String?,
      vehicleLabel: vehicleLabel,
      offeredPrice: double.parse(json['offered_price'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  FlashProposal toEntity({
    double? etaMinutes,
    double? driverRatingAvg,
    int driverFinishedTrips = 0,
  }) =>
      FlashProposal(
        candidateId: candidateId,
        tripId: tripId,
        driverProfileId: driverProfileId,
        driverName: driverName,
        driverPhotoUrl: driverPhotoUrl,
        vehicleLabel: vehicleLabel,
        offeredPrice: offeredPrice,
        createdAt: createdAt,
        etaMinutes: etaMinutes,
        driverRatingAvg: driverRatingAvg,
        driverFinishedTrips: driverFinishedTrips,
      );
}
