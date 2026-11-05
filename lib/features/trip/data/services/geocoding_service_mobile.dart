import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kz_servicos_app/core/constants/app_maps.dart';
import 'package:kz_servicos_app/core/maps/google_maps_api_key.dart';

class GeocodingService {
  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> reverseGeocode(LatLng position) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '${position.latitude},${position.longitude}',
      'key': GoogleMapsApiKey.value,
      'language': AppMaps.languageCode,
      'region': AppMaps.regionCode,
    });

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      return results[0]['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }
}
