import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_with_candidates.dart';

abstract class TripRepository {
  /// Creates addresses and a trip in Supabase.
  /// Returns the created [Trip] on success.
  Future<Trip> createTrip(TripRequest request);

  /// Returns all active/scheduled trips for the given client,
  /// ordered by [scheduledDatetime] ascending.
  Future<List<ScheduledTrip>> getScheduledTrips(String clientId);

  /// Returns trips for [clientId] that are in `searching_drivers` status
  /// and have at least one driver candidate with `status = 'accepted'`,
  /// alongside the list of those candidates.
  Future<List<TripWithCandidates>> getTripsAwaitingClientConfirmation(
    String clientId,
  );

  /// Assigns [driverProfileId] (and optionally [vehicleId]) to [tripId],
  /// sets [offeredPrice] as the final price, and flips the trip to
  /// `awaiting_driver_confirmation` until the driver confirms.
  Future<void> acceptDriverCandidate({
    required String tripId,
    required String driverProfileId,
    String? vehicleId,
    double? offeredPrice,
  });

  /// Cancels [tripId] by setting its status to `cancelled`.
  Future<void> cancelTrip(String tripId);
}
