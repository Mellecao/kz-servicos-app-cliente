import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/models/address_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/driver_candidate_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/scheduled_trip_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_model.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_with_candidates.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Future<Trip> createTrip(TripRequest request) async {
    // 1. Fetch trip service category
    final serviceCategoryId = await _fetchTripCategoryId();

    // 2. Create pickup address
    final pickupId = await _insertAddress(
      AddressModel.fromEntity(request.pickupAddress),
    );

    // 3. Create dropoff address
    final dropoffId = await _insertAddress(
      AddressModel.fromEntity(request.dropoffAddress),
    );

    // 4. Create trip
    final tripJson = TripModel.buildInsertJson(
      clientId: request.clientId,
      serviceCategoryId: serviceCategoryId,
      pickupAddressId: pickupId,
      dropoffAddressId: dropoffId,
      scheduledDatetime: request.scheduledDatetime,
      passengerCount: request.passengerCount,
      childrenCount: request.childrenCount,
      luggageCount: request.luggageCount,
      observations: request.combinedObservations,
      paymentMethod: request.paymentMethod,
    );

    final tripResponse = await _client
        .from('trips')
        .insert(tripJson)
        .select();

    if (tripResponse.isEmpty) {
      throw Exception('Failed to create trip: empty response');
    }

    return TripModel.fromJson(tripResponse.first).toEntity();
  }

  Future<String> _fetchTripCategoryId() async {
    final response = await _client
        .from('service_categories')
        .select('id, name, service_type')
        .eq('service_type', 'trip')
        .limit(1);

    if (response.isEmpty) {
      throw Exception(
        'Service category for trips not found. '
        'Ensure seed data exists in service_categories.',
      );
    }

    return response.first['id'] as String;
  }

  Future<String> _insertAddress(AddressModel address) async {
    final response = await _client
        .from('addresses')
        .insert(address.toJson())
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to create address: empty response');
    }

    return response.first['id'] as String;
  }

  static const _activeStatuses = [
    'open',
    'under_review',
    'searching_drivers',
    'awaiting_client_confirmation',
    'awaiting_driver_confirmation',
    'scheduled',
  ];

  @override
  Future<List<ScheduledTrip>> getScheduledTrips(String clientId) async {
    final response = await _client
        .from('trips')
        .select(
          '*, '
          'pickup_address:addresses!pickup_address_id(*), '
          'dropoff_address:addresses!dropoff_address_id(*), '
          'driver_profiles(provider_profiles(users(full_name)))',
        )
        .eq('client_id', clientId)
        .inFilter('status', _activeStatuses)
        .order('scheduled_datetime', ascending: true);

    return response
        .map((json) => ScheduledTripModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<List<TripWithCandidates>> getTripsAwaitingClientConfirmation(
    String clientId,
  ) async {
    // 1. Trips for this client in 'searching_drivers' status.
    final tripsResponse = await _client
        .from('trips')
        .select(
          '*, '
          'pickup_address:addresses!pickup_address_id(*), '
          'dropoff_address:addresses!dropoff_address_id(*), '
          'driver_profiles(provider_profiles(users(full_name)))',
        )
        .eq('client_id', clientId)
        .eq('status', 'searching_drivers')
        .order('scheduled_datetime', ascending: true);

    if (tripsResponse.isEmpty) return [];

    final tripIds = tripsResponse
        .map((row) => row['id'] as String)
        .toList(growable: false);

    // 2. Accepted candidates for those trips, joined with driver+user+vehicle.
    final candidatesResponse = await _client
        .from('trip_driver_candidates')
        .select(
          'id, trip_id, driver_profile_id, status, '
          'driver_profiles(id, '
          'provider_profiles(users(full_name, avatar_url)), '
          'vehicles(id, brand, model, year, color, license_plate, is_active))',
        )
        .inFilter('trip_id', tripIds)
        .eq('status', 'accepted');

    final candidatesByTrip = <String, List<DriverCandidateModel>>{};
    for (final row in candidatesResponse) {
      final model = DriverCandidateModel.fromJson(row);
      candidatesByTrip.putIfAbsent(model.tripId, () => []).add(model);
    }

    // 3. Pair each trip with its accepted candidates; skip trips without any.
    final result = <TripWithCandidates>[];
    for (final row in tripsResponse) {
      final id = row['id'] as String;
      final tripCandidates = candidatesByTrip[id];
      if (tripCandidates == null || tripCandidates.isEmpty) continue;
      result.add(
        TripWithCandidates(
          trip: ScheduledTripModel.fromJson(row).toEntity(),
          candidates:
              tripCandidates.map((c) => c.toEntity()).toList(growable: false),
        ),
      );
    }
    return result;
  }

  @override
  Future<void> acceptDriverCandidate({
    required String tripId,
    required String driverProfileId,
    String? vehicleId,
  }) async {
    // 1. Assign driver + flip status to scheduled.
    final updates = <String, dynamic>{
      'driver_profile_id': driverProfileId,
      'status': 'scheduled',
    };
    if (vehicleId != null) updates['vehicle_id'] = vehicleId;

    await _client.from('trips').update(updates).eq('id', tripId);

    // 2. Drop all candidates for this trip — the choice has been made.
    await _client
        .from('trip_driver_candidates')
        .delete()
        .eq('trip_id', tripId);
  }
}
