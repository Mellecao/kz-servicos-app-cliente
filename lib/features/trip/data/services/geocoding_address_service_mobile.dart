import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';

class GeocodingAddressService {
  static const String _apiKey = 'AIzaSyChT4wSYd-b3fT7xfEvUvmgJ0QfZv7MYSE';

  final http.Client _client;

  GeocodingAddressService({http.Client? client})
    : _client = client ?? http.Client();

  /// Reverse geocodes a LatLng into a structured [TripAddress].
  Future<TripAddress?> reverseGeocodeToAddress(LatLng position) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '${position.latitude},${position.longitude}',
        'key': _apiKey,
        'language': 'pt-BR',
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final result = results[0] as Map<String, dynamic>;
      return _parseGeocodingResult(result, position);
    } catch (_) {
      return null;
    }
  }

  /// Fetches structured address from a Google Place ID.
  Future<TripAddress?> getAddressFromPlaceId(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'place_id': placeId,
        'key': _apiKey,
        'language': 'pt-BR',
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final result = results[0] as Map<String, dynamic>;
      final location =
          result['geometry']?['location'] as Map<String, dynamic>?;
      final latLng = location != null
          ? LatLng(
              (location['lat'] as num).toDouble(),
              (location['lng'] as num).toDouble(),
            )
          : null;

      return _parseGeocodingResult(result, latLng);
    } catch (_) {
      return null;
    }
  }

  TripAddress? _parseGeocodingResult(
    Map<String, dynamic> result,
    LatLng? fallbackPosition,
  ) {
    final formattedAddress = result['formatted_address'] as String?;
    if (formattedAddress == null) return null;

    final components =
        (result['address_components'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    String? street;
    String? number;
    String? neighborhood;
    String city = '';
    String state = '';
    String? zipCode;

    for (final comp in components) {
      final types = (comp['types'] as List?)?.cast<String>() ?? [];
      final longName = comp['long_name'] as String? ?? '';

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
        state = comp['short_name'] as String? ?? longName;
      } else if (types.contains('postal_code')) {
        zipCode = longName;
      }
    }

    final placeId = result['place_id'] as String?;
    final location =
        result['geometry']?['location'] as Map<String, dynamic>?;
    final lat = location != null
        ? (location['lat'] as num).toDouble()
        : fallbackPosition?.latitude ?? 0;
    final lng = location != null
        ? (location['lng'] as num).toDouble()
        : fallbackPosition?.longitude ?? 0;

    return TripAddress(
      googlePlaceId: placeId,
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
