import 'package:supabase_flutter/supabase_flutter.dart';

class SystemSettingsRepository {
  SystemSettingsRepository._();
  static final SystemSettingsRepository instance = SystemSettingsRepository._();

  static const String _key = 'scheduled_quote_admin_override';
  static const Duration _ttl = Duration(seconds: 60);

  String? _cachedValue;
  DateTime? _cachedAt;

  Future<String> fetchScheduledQuoteOverride() async {
    final now = DateTime.now();
    if (_cachedValue != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _ttl) {
      return _cachedValue!;
    }

    try {
      final response = await Supabase.instance.client
          .from('system_settings')
          .select('value')
          .eq('key', _key)
          .maybeSingle();

      final raw = response == null ? null : response['value'];
      final value = _normalize(raw);
      _cachedValue = value;
      _cachedAt = now;
      return value;
    } catch (_) {
      return 'auto';
    }
  }

  String _normalize(Object? raw) {
    if (raw is String &&
        (raw == 'auto' || raw == 'force_enabled' || raw == 'force_disabled')) {
      return raw;
    }
    return 'auto';
  }
}
