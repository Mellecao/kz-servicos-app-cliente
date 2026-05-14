import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/services/google_maps_js_types.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';

class GeocodingAddressService {
  final JsGeocoder _geocoder = JsGeocoder();

  GeocodingAddressService({dynamic client});

  Future<TripAddress?> reverseGeocodeToAddress(LatLng position) async {
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

      return _parseResult(results[0], position);
    } catch (_) {
      return null;
    }
  }

  Future<TripAddress?> getAddressFromPlaceId(String placeId) async {
    final request = <String, Object>{
      'placeId': placeId,
    }.jsify() as JSObject;

    try {
      final response = await _geocoder.geocode(request).toDart;
      final results = response.results.toDart;
      if (results.isEmpty) return null;

      final result = results[0];
      final lat = result.geometry.location.lat();
      final lng = result.geometry.location.lng();
      return _parseResult(result, LatLng(lat, lng));
    } catch (_) {
      return null;
    }
  }

  TripAddress? _parseResult(JsGeocoderResult result, LatLng? fallback) {
    final formattedAddress = result.formattedAddress;

    String? street;
    String? number;
    String? neighborhood;
    String city = '';
    String state = '';
    String? zipCode;

    final components = result.addressComponents?.toDart;
    if (components != null) {
      for (final comp in components) {
        final types = comp.types.toDart.map((t) => t.toDart).toList();
        final longName = comp.longName;

        if (types.contains('route')) {
          street = longName;
        } else if (types.contains('street_number')) {
          number = longName;
        } else if (types.contains('sublocality_level_1') ||
            types.contains('sublocality')) {
          neighborhood = longName;
        } else if (types.contains('administrative_area_level_2')) {
          city = longName;
        } else if (types.contains('administrative_area_level_1')) {
          state = comp.shortName;
        } else if (types.contains('postal_code')) {
          zipCode = longName;
        }
      }
    }

    final lat = result.geometry.location.lat();
    final lng = result.geometry.location.lng();

    return TripAddress(
      googlePlaceId: result.placeId,
      formattedAddress: formattedAddress,
      street: street,
      number: number,
      neighborhood: neighborhood,
      city: city.isEmpty ? 'Desconhecida' : city,
      state: state.isEmpty ? 'XX' : state,
      zipCode: zipCode,
      latitude: lat,
      longitude: lng,
    );
  }
}
