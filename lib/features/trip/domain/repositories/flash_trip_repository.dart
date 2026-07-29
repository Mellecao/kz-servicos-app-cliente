import '../entities/trip_address.dart';

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

  /// End-to-end helper for the client "Flash" flow: inserts pickup/dropoff
  /// addresses, resolves the trip service category, and calls
  /// `create_flash_trip`. Returns the new trip id.
  Future<String> createFlashTripFromAddresses({
    required TripAddress pickupAddress,
    required TripAddress dropoffAddress,
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
