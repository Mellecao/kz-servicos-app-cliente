import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlaceDetailsService {
  static const String _apiKey = 'AIzaSyChT4wSYd-b3fT7xfEvUvmgJ0QfZv7MYSE';

  final http.Client _client;

  PlaceDetailsService({http.Client? client})
    : _client = client ?? http.Client();

  Future<LatLng?> getPlaceLatLng(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'geometry',
        'key': _apiKey,
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final location =
          result['geometry']?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      return LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
