import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/models/address_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/driver_candidate_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/scheduled_trip_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_model.dart';

import 'package:kz_servicos_app/features/trip/data/repositories/trip_details_persistence.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_with_candidates.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl({
    required SupabaseClient client,
    TripDetailsPersistence? detailsPersistence,
  }) : _client = client,
       _detailsPersistence =
           detailsPersistence ??
           TripDetailsPersistence(
             insertRows: (table, rows) async {
               await client.from(table).insert(rows);
             },
           );

  final SupabaseClient _client;
  final TripDetailsPersistence _detailsPersistence;

  @override
  Future<Trip> createTrip(TripRequest request) async {
    final createdAddressIds = <String>[];
    String? createdTripId;
    try {
      // 1. Fetch trip service category
      final serviceCategoryId = await _fetchTripCategoryId();

      // 2. Create pickup address
      final pickupId = await _insertAddress(
        AddressModel.fromEntity(request.pickupAddress),
      );
      createdAddressIds.add(pickupId);

      // 3. Create dropoff address
      final dropoffId = await _insertAddress(
        AddressModel.fromEntity(request.dropoffAddress),
      );
      createdAddressIds.add(dropoffId);

      final returnPickupId = request.returnPickupAddress == null
          ? null
          : await _insertAddress(
              AddressModel.fromEntity(request.returnPickupAddress!),
            );
      if (returnPickupId != null) createdAddressIds.add(returnPickupId);
      final returnDropoffId = request.returnDropoffAddress == null
          ? null
          : await _insertAddress(
              AddressModel.fromEntity(request.returnDropoffAddress!),
            );

      if (returnDropoffId != null) createdAddressIds.add(returnDropoffId);

      // 4. Create trip
      final tripJson = TripModel.buildInsertJson(
        clientId: request.clientId,
        serviceCategoryId: serviceCategoryId,
        pickupAddressId: pickupId,
        dropoffAddressId: dropoffId,
        scheduledDatetime: request.scheduledDatetime,
        passengerCount: request.aggregatePassengerCount,
        childrenCount: request.aggregateChildrenCount,
        luggageCount: request.aggregateLuggageCount,
        observations: request.combinedObservations,
        paymentMethod: request.paymentMethod,
        isRoundTrip: request.isRoundTrip,
        returnDatetime: request.returnDatetime,
        returnPickupAddressId: returnPickupId,
        returnDropoffAddressId: returnDropoffId,
        tripType: request.tripType,
      );

      final tripResponse = await _client
          .from('trips')
          .insert(tripJson)
          .select();

      if (tripResponse.isEmpty) {
        throw Exception('Failed to create trip: empty response');
      }

      final trip = TripModel.fromJson(tripResponse.first).toEntity();
      createdTripId = trip.id;

      await _detailsPersistence.persist(
        tripId: trip.id,
        passengers: request.passengers,
        luggage: request.luggage,
      );

      // Outbound stops only. Each stop address is persisted before trip_stops.
      if (request.stops.isNotEmpty) {
        for (var index = 0; index < request.stops.length; index++) {
          await _client.rpc(
            'insert_trip_stop_address',
            params: {
              'p_trip_id': trip.id,
              'p_stop_order': index + 1,
              'p_address': AddressModel.fromEntity(
                request.stops[index],
              ).toJson(),
            },
          );
        }
      }

      return trip;
    } catch (error, stackTrace) {
      try {
        if (createdTripId != null) {
          await _client.rpc(
            'rollback_failed_trip_creation',
            params: {'p_trip_id': createdTripId},
          );
        } else if (createdAddressIds.isNotEmpty) {
          await _client
              .from('addresses')
              .delete()
              .inFilter('id', createdAddressIds);
        }
      } catch (_) {
        // Preserve the original write failure; cleanup is best-effort.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Public helper para fluxos que precisam persistir moradas antes de
  /// criar uma trip (Subprojeto 2B — Escolha seu Motorista navega pra
  /// nova tela com os IDs em vez de criar a trip direto).
  Future<
    ({
      String pickupAddressId,
      String dropoffAddressId,
      String? returnPickupAddressId,
      String? returnDropoffAddressId,
      String serviceCategoryId,
    })
  >
  persistAddressesForDirectRequest({
    required TripAddress pickupAddress,
    required TripAddress dropoffAddress,
    TripAddress? returnPickupAddress,
    TripAddress? returnDropoffAddress,
  }) async {
    final categoryId = await _fetchTripCategoryId();
    final pickupId = await _insertAddress(
      AddressModel.fromEntity(pickupAddress),
    );
    final dropoffId = await _insertAddress(
      AddressModel.fromEntity(dropoffAddress),
    );
    final returnPickupId = returnPickupAddress == null
        ? null
        : await _insertAddress(AddressModel.fromEntity(returnPickupAddress));
    final returnDropoffId = returnDropoffAddress == null
        ? null
        : await _insertAddress(AddressModel.fromEntity(returnDropoffAddress));
    return (
      pickupAddressId: pickupId,
      dropoffAddressId: dropoffId,
      returnPickupAddressId: returnPickupId,
      returnDropoffAddressId: returnDropoffId,
      serviceCategoryId: categoryId,
    );
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
          'id, trip_id, driver_profile_id, status, offered_price, admin_approved, '
          'driver_profiles(id, '
          'provider_profiles(users(full_name, avatar_url)), '
          'driver_profile_photos(photo_url, sort_order), '
          'vehicles(id, brand, model, year, color, license_plate, is_active, '
          'vehicle_photos(photo_url, photo_type)))',
        )
        .inFilter('trip_id', tripIds)
        .eq('admin_approved', true);

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
          candidates: tripCandidates
              .map((c) => c.toEntity())
              .toList(growable: false),
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
    double? offeredPrice,
  }) async {
    // 1. Assign driver + flip status to the driver's final confirmation step.
    final updates = <String, dynamic>{
      'driver_profile_id': driverProfileId,
      'status': 'awaiting_driver_confirmation',
    };
    if (vehicleId != null) updates['vehicle_id'] = vehicleId;
    if (offeredPrice != null) updates['final_price'] = offeredPrice;

    await _client.from('trips').update(updates).eq('id', tripId);

    // 2. Keep candidate history so the driver can be re-notified while the
    // trip is waiting for final confirmation.
    await _client
        .from('trip_driver_candidates')
        .update({
          'status': 'accepted',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
          if (offeredPrice case final price?) 'offered_price': price,
        })
        .eq('trip_id', tripId)
        .eq('driver_profile_id', driverProfileId);

    await _client
        .from('trip_driver_candidates')
        .update({
          'status': 'rejected',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('trip_id', tripId)
        .neq('driver_profile_id', driverProfileId);
  }

  @override
  Future<void> cancelTrip(String tripId) async {
    await _client
        .from('trips')
        .update({
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', tripId);
  }
}
