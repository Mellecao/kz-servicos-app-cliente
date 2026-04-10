import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  static const String _apiKey = 'AIzaSyChT4wSYd-b3fT7xfEvUvmgJ0QfZv7MYSE';

  final http.Client _client;

  DirectionsService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<LatLng>> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final params = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination':
          '${destination.latitude},${destination.longitude}',
      'key': _apiKey,
      'language': 'pt-BR',
    };
    if (waypoints.isNotEmpty) {
      params['waypoints'] = waypoints
          .map((wp) => '${wp.latitude},${wp.longitude}')
          .join('|');
    }
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      params,
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return [];

      final polyline =
          routes[0]['overview_polyline']['points'] as String;
      return _decodePolyline(polyline);
    } catch (_) {
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
