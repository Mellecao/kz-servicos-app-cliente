import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/trip_address.dart';
import '../../domain/repositories/flash_trip_repository.dart';
import '../models/address_model.dart';

class FlashTripRepositoryImpl implements FlashTripRepository {
  final SupabaseClient client;
  FlashTripRepositoryImpl({required this.client});

  @override
  Future<String> createFlashTrip({
    required String pickupAddressId,
    required String dropoffAddressId,
    required String serviceCategoryId,
    required int passengerCount,
    required int childrenCount,
    required int luggageCount,
    required String observations,
  }) async {
    final result = await client.rpc('create_flash_trip', params: {
      'p_pickup_address_id': pickupAddressId,
      'p_dropoff_address_id': dropoffAddressId,
      'p_service_category_id': serviceCategoryId,
      'p_passenger_count': passengerCount,
      'p_children_count': childrenCount,
      'p_luggage_count': luggageCount,
      'p_observations': observations,
    });
    return result as String;
  }

  @override
  Future<String> createFlashTripFromAddresses({
    required TripAddress pickupAddress,
    required TripAddress dropoffAddress,
    required int passengerCount,
    required int childrenCount,
    required int luggageCount,
    required String observations,
  }) async {
    final serviceCategoryId = await _fetchTripCategoryId();
    final pickupId = await _insertAddress(
      AddressModel.fromEntity(pickupAddress),
    );
    final dropoffId = await _insertAddress(
      AddressModel.fromEntity(dropoffAddress),
    );
    return createFlashTrip(
      pickupAddressId: pickupId,
      dropoffAddressId: dropoffId,
      serviceCategoryId: serviceCategoryId,
      passengerCount: passengerCount,
      childrenCount: childrenCount,
      luggageCount: luggageCount,
      observations: observations,
    );
  }

  Future<String> _fetchTripCategoryId() async {
    final response = await client
        .from('service_categories')
        .select('id')
        .eq('service_type', 'trip')
        .limit(1);
    if (response.isEmpty) {
      throw Exception(
        'Service category for trips not found. Ensure seed data exists.',
      );
    }
    return response.first['id'] as String;
  }

  Future<String> _insertAddress(AddressModel address) async {
    final response = await client
        .from('addresses')
        .insert(address.toJson())
        .select();
    if (response.isEmpty) {
      throw Exception('Failed to insert address: empty response');
    }
    return response.first['id'] as String;
  }

  @override
  Future<void> acceptProposal(String candidateId) async {
    await client.rpc('client_accept_flash_proposal',
        params: {'p_candidate_id': candidateId});
  }

  @override
  Future<void> cancelFlashTrip(String tripId, String reason) async {
    await client.rpc('cancel_flash_trip',
        params: {'p_trip_id': tripId, 'p_reason': reason});
  }

  @override
  Stream<List<Map<String, dynamic>>> watchProposals(String tripId) {
    return client
        .from('trip_driver_candidates')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) =>
                r['status'] == 'accepted' && r['offered_price'] != null)
            .toList());
  }

  @override
  Stream<Map<String, dynamic>> watchTripStatus(String tripId) {
    return client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((rows) => rows.isEmpty ? <String, dynamic>{} : rows.first);
  }

  @override
  Future<Map<String, dynamic>> fetchDriverDetails(String driverProfileId) async {
    final detailsFuture = client
        .from('driver_profiles')
        .select('*, provider_profiles(user:users(name))')
        .eq('id', driverProfileId)
        .single();
    final ratingsFuture = client
        .from('ratings')
        .select('rating')
        .eq('rated_user_id', driverProfileId);
    final countFuture = client
        .from('trips')
        .select('id')
        .eq('driver_profile_id', driverProfileId)
        .eq('status', 'finished')
        .count();
    final photosFuture = client
        .from('driver_profile_photos')
        .select('url')
        .eq('driver_profile_id', driverProfileId);
    final vehiclePhotosFuture = client
        .from('vehicle_photos')
        .select('url')
        .eq('driver_profile_id', driverProfileId);

    final details = await detailsFuture;
    final ratings = await ratingsFuture;
    final count = await countFuture;
    final photos = await photosFuture;
    final vehiclePhotos = await vehiclePhotosFuture;

    final ratingsList =
        ratings.map((r) => (r)['rating'] as num).toList();
    final avg = ratingsList.isEmpty
        ? null
        : ratingsList.fold<double>(0, (a, b) => a + b.toDouble()) /
            ratingsList.length;
    return {
      'details': details,
      'ratingAvg': avg,
      'ratingsCount': ratingsList.length,
      'finishedTrips': count.count,
      'profilePhotos':
          photos.map((e) => (e)['url'] as String).toList(),
      'vehiclePhotos':
          vehiclePhotos.map((e) => (e)['url'] as String).toList(),
    };
  }
}
