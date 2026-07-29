abstract class FlashTripRepository {
  Future<String> createFlashTrip({
    required String pickupAddressId,
    required String dropoffAddressId,
    required String serviceCategoryId,
    required int passengerCount,
    required int childrenCount,
    required int luggageCount,
    required String observations,
  });

  Future<void> acceptProposal(String candidateId);
  Future<void> cancelFlashTrip(String tripId, String reason);
  Stream<List<Map<String, dynamic>>> watchProposals(String tripId);
  Stream<Map<String, dynamic>> watchTripStatus(String tripId);
  Future<Map<String, dynamic>> fetchDriverDetails(String driverProfileId);
}
