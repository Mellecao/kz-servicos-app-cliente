import 'package:supabase_flutter/supabase_flutter.dart';

/// Interpreta o jsonb de `system_settings.trips_enabled`: só `true` (ou a
/// string `'true'`) liga as viagens. Qualquer outra coisa conta como desligado.
bool parseTripsEnabled(Object? raw) => raw == true || raw == 'true';

abstract class TripsEnabledRepository {
  /// Lê o interruptor `trips_enabled`. Nunca lança: falha ⇒ `false`.
  Future<bool> fetchTripsEnabled();
}

class SupabaseTripsEnabledRepository implements TripsEnabledRepository {
  SupabaseTripsEnabledRepository({required SupabaseClient client})
    : _read = (() async {
        final row = await client
            .from('system_settings')
            .select('value')
            .eq('key', 'trips_enabled')
            .maybeSingle();
        return row?['value'];
      });

  /// Para testes: troca a leitura ao banco por [reader].
  SupabaseTripsEnabledRepository.withReader(Future<Object?> Function() reader)
    : _read = reader;

  final Future<Object?> Function() _read;

  @override
  Future<bool> fetchTripsEnabled() async {
    try {
      return parseTripsEnabled(await _read());
    } catch (_) {
      return false;
    }
  }
}
