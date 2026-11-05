import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Configuração de mapas para Angola. Fonte única: Places, Geocoding e
/// Directions usam estas constantes.
abstract final class AppMaps {
  /// Luanda.
  static const LatLng defaultCenter = LatLng(-8.8383, 13.2344);

  /// Código de região (ISO 3166-1 alpha-2, minúsculas) de Angola.
  static const String regionCode = 'ao';

  /// Idioma das respostas do Google.
  static const String languageCode = 'pt-PT';

  /// Restrição de país da API legada de autocomplete.
  static const String placesComponents = 'country:ao';
}
