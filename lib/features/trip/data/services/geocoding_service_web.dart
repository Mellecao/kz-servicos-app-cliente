import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/services/google_maps_js_types.dart';

class GeocodingService {
  final JsGeocoder _geocoder = JsGeocoder();

  GeocodingService({dynamic client});

  Future<String?> reverseGeocode(LatLng position) async {
    final request = <String, Object>{
      'location': <String, Object>{
        'lat': position.latitude,
        'lng': position.longitude,
      },
    }.jsify() as JSObject;

    try {
      final response = await _geocoder.geocode(request).toDart;
      final results = response.results.toDart;
      if (results.isEmpty) return null;

      return results[0].formattedAddress;
    } catch (_) {
      return null;
    }
  }
}
