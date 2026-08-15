import 'package:supabase_flutter/supabase_flutter.dart';

/// Restores the actionable step of a choose-driver scheduled trip after the
/// process was killed or the app was reopened.
class ActiveScheduledDirectGate {
  ActiveScheduledDirectGate({required this.client});

  final SupabaseClient client;

  Future<String?> resolveTargetPath() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final rows = await client
        .from('trips')
        .select('id, status')
        .eq('client_id', user.id)
        .eq('trip_type', 'scheduled_choose_driver')
        .inFilter('status', const [
          'awaiting_driver_confirmation',
          'awaiting_client_confirmation',
        ])
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    final trip = rows.first;
    return resolvePathForTrip(
      tripId: trip['id'] as String,
      status: trip['status'] as String,
    );
  }

  static String? resolvePathForTrip({
    required String tripId,
    required String status,
  }) {
    return switch (status) {
      'awaiting_client_confirmation' =>
        '/scheduled-choose-driver/price-review/$tripId',
      'awaiting_driver_confirmation' =>
        '/scheduled-choose-driver/awaiting/$tripId',
      _ => null,
    };
  }
}
