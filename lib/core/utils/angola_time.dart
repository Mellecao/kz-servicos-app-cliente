import 'package:timezone/timezone.dart' as tz;

/// Hora de Angola: `Africa/Luanda`, UTC+1, sem hora de verão.
class AngolaTime {
  static const Duration _offset = Duration(hours: 1);

  /// Instante vindo do backend (UTC) como hora civil de Luanda.
  static DateTime fromBackend(String value) {
    return DateTime.parse(value).toUtc().add(_offset);
  }

  static DateTime? maybeFromBackend(String? value) {
    if (value == null || value.isEmpty) return null;
    return fromBackend(value);
  }

  /// Agora em Luanda. Requer `initializeTimeZones()` (feito em `main`).
  static tz.TZDateTime now() {
    return tz.TZDateTime.now(tz.getLocation('Africa/Luanda'));
  }
}
