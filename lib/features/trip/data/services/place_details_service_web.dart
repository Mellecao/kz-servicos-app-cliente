import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/services/google_maps_js_types.dart';

class PlaceDetailsService {
  final JsGeocoder _geocoder = JsGeocoder();

  PlaceDetailsService({dynamic client});

  Future<LatLng?> getPlaceLatLng(String placeId) async {
    final request = <String, Object>{
      'placeId': placeId,
    }.jsify() as JSObject;

    try {
      final response = await _geocoder.geocode(request).toDart;
      final results = response.results.toDart;
      if (results.isEmpty) return null;

      final location = results[0].geometry.location;
      return LatLng(location.lat(), location.lng());
    } catch (_) {
      return null;
    }
  }
}
