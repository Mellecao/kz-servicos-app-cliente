import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduledDirectRequestRepository {
  Future<String> sendRequest({
    required String driverProfileId,
    required String pickupAddressId,
    required String dropoffAddressId,
    required String serviceCategoryId,
    required int passengerCount,
    required DateTime scheduledDatetime,
    String? observation,
  }) async {
    final result = await Supabase.instance.client.rpc(
      'client_send_scheduled_direct_request',
      params: {
        'driver_profile_id_input': driverProfileId,
        'pickup_address_id_input': pickupAddressId,
        'dropoff_address_id_input': dropoffAddressId,
        'service_category_id_input': serviceCategoryId,
        'passenger_count_input': passengerCount,
        'observation_input': observation,
        'scheduled_datetime_input': scheduledDatetime.toUtc().toIso8601String(),
      },
    );
    return result as String;
  }

  Future<void> acceptPrice(String tripId) async {
    await Supabase.instance.client.rpc(
      'client_accept_scheduled_price',
      params: {'trip_id_input': tripId},
    );
  }

  Future<void> rejectPrice(String tripId) async {
    await Supabase.instance.client.rpc(
      'client_reject_scheduled_price',
      params: {'trip_id_input': tripId},
    );
  }

  Future<void> cancel(String tripId, String reason) async {
    try {
      await Supabase.instance.client.rpc(
        'cancel_scheduled_choose_driver_trip',
        params: {
          'p_trip_id': tripId,
          'p_reason': reason.isEmpty ? null : reason,
        },
      );
    } on PostgrestException catch (error) {
      final alreadyCancelled =
          error.code == 'P0001' &&
          error.message.toLowerCase().contains('status cancelled');
      if (!alreadyCancelled) rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchActiveRequest(String clientId) async {
    final response = await Supabase.instance.client
        .from('trips')
        .select('''
          id, driver_profile_id, status,
          driver_profiles ( provider_profiles ( users ( full_name, avatar_url ) ) ),
          trip_driver_candidates ( offered_price, status )
        ''')
        .eq('client_id', clientId)
        .eq('trip_type', 'scheduled_choose_driver')
        .inFilter('status', [
          'awaiting_driver_confirmation',
          'awaiting_client_confirmation',
        ])
        .limit(1)
        .maybeSingle();

    return response;
  }
}
