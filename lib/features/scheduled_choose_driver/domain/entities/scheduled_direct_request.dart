enum ScheduledDirectStatus {
  awaitingDriver,
  priceOffered,
  rejected,
  confirmed,
  cancelled,
}

ScheduledDirectStatus scheduledDirectStatusFrom({
  required String tripStatus,
  required String candidateStatus,
}) {
  if (tripStatus == 'cancelled') return ScheduledDirectStatus.cancelled;
  if (tripStatus == 'scheduled') return ScheduledDirectStatus.confirmed;
  if (tripStatus == 'awaiting_client_confirmation' && candidateStatus == 'accepted') {
    return ScheduledDirectStatus.priceOffered;
  }
  if (tripStatus == 'searching_drivers' && candidateStatus == 'rejected') {
    return ScheduledDirectStatus.rejected;
  }
  if (tripStatus == 'awaiting_driver_confirmation' && candidateStatus == 'pending') {
    return ScheduledDirectStatus.awaitingDriver;
  }
  return ScheduledDirectStatus.awaitingDriver;
}

class ScheduledDirectRequest {
  final String tripId;
  final String driverProfileId;
  final ScheduledDirectStatus status;
  final double? offeredPrice;
  final String driverName;
  final String? driverAvatarUrl;

  const ScheduledDirectRequest({
    required this.tripId,
    required this.driverProfileId,
    required this.status,
    required this.offeredPrice,
    required this.driverName,
    required this.driverAvatarUrl,
  });
}
