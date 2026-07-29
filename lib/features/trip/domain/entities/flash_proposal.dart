import 'package:equatable/equatable.dart';

class FlashProposal extends Equatable {
  final String candidateId;
  final String tripId;
  final String driverProfileId;
  final String driverName;
  final String? driverPhotoUrl;
  final String vehicleLabel;
  final double offeredPrice;
  final DateTime createdAt;
  final double? etaMinutes;
  final double? driverRatingAvg;
  final int driverFinishedTrips;

  const FlashProposal({
    required this.candidateId,
    required this.tripId,
    required this.driverProfileId,
    required this.driverName,
    required this.driverPhotoUrl,
    required this.vehicleLabel,
    required this.offeredPrice,
    required this.createdAt,
    required this.etaMinutes,
    required this.driverRatingAvg,
    required this.driverFinishedTrips,
  });

  @override
  List<Object?> get props => [candidateId, tripId, offeredPrice, createdAt];
}
