import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/available_driver.dart';

class AvailableDriversRepository {
  Future<List<AvailableDriver>> fetchApproved() async {
    final response =
        await Supabase.instance.client
                .from('driver_profiles')
                .select('''
          id,
          provider_profiles!inner (
            status,
            average_rating,
            total_ratings,
            users!inner ( full_name, avatar_url )
          ),
          vehicles ( brand, model, color, license_plate, is_active )
        ''')
                .eq('provider_profiles.status', 'approved')
            as List<dynamic>;

    return response
        .whereType<Map<String, dynamic>>()
        .map((row) {
          final providerRaw = row['provider_profiles'];
          final provider = providerRaw is Map<String, dynamic>
              ? providerRaw
              : null;
          if (provider == null) return null;
          final userRaw = provider['users'];
          final user = userRaw is Map<String, dynamic> ? userRaw : null;
          if (user == null) return null;

          final flatMap = <String, dynamic>{
            'driver_profile_id': row['id'],
            'full_name': user['full_name'],
            'avatar_url': user['avatar_url'],
            'average_rating': provider['average_rating'],
            'total_ratings': provider['total_ratings'] ?? 0,
            'vehicles': row['vehicles'] ?? const [],
          };
          return AvailableDriver.fromMap(flatMap);
        })
        .whereType<AvailableDriver>()
        .toList();
  }
}
