import 'package:supabase_flutter/supabase_flutter.dart';

class ActiveFlashGate {
  final SupabaseClient client;
  ActiveFlashGate({required this.client});

  Future<String?> resolveTargetPath() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final rows = await client
        .from('trips')
        .select('id, status')
        .eq('client_id', user.id)
        .eq('trip_type', 'flash')
        .inFilter('status', [
          'searching_drivers',
          'awaiting_driver_confirmation',
          'scheduled',
          'started',
        ])
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final trip = rows.first;
    switch (trip['status']) {
      case 'searching_drivers':
      case 'awaiting_driver_confirmation':
        return '/flash/searching/${trip['id']}';
      case 'scheduled':
      case 'started':
        return '/trip?activeTripId=${trip['id']}';
    }
    return null;
  }
}
