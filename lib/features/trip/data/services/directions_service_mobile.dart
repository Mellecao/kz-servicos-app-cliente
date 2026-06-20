import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kz_servicos_app/core/maps/google_maps_api_key.dart';

class DirectionsResult {
  final List<LatLng> points;
  final int durationSeconds;
  final int distanceMeters;

  const DirectionsResult({
    required this.points,
    required this.durationSeconds,
    this.distanceMeters = 0,
  });
}

class DirectionsService {
  final http.Client _client;

  DirectionsService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<LatLng>> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final result = await fetchRouteWithDuration(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );
    return result.points;
  }

  Future<DirectionsResult> fetchRouteWithDuration({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final google = await _fetchGoogleRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );
    if (google.points.isNotEmpty) return google;
    return _fetchOsrmRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );
  }

  Future<DirectionsResult> _fetchGoogleRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final params = <String, String>{
      'origin': _formatLatLng(origin),
      'destination': _formatLatLng(destination),
      'mode': 'driving',
      'language': 'pt-BR',
      'key': GoogleMapsApiKey.value,
      if (waypoints.isNotEmpty)
        'waypoints': waypoints.map(_formatLatLng).join('|'),
    };

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      params,
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }

      final route = routes.first as Map<String, dynamic>;
      final legs = (route['legs'] as List? ?? []).cast<Map<String, dynamic>>();
      final points = _decodeRoutePoints(route, legs);
      if (points.isEmpty) {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }
      return DirectionsResult(
        points: points,
        durationSeconds: _sumLegValue(legs, 'duration'),
        distanceMeters: _sumLegValue(legs, 'distance'),
      );
    } catch (_) {
      return const DirectionsResult(points: [], durationSeconds: 0);
    }
  }

  Future<DirectionsResult> _fetchOsrmRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final coords = [
      origin,
      ...waypoints,
      destination,
    ].map((p) => '${p.longitude},${p.latitude}').join(';');
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coords',
      const {'overview': 'full', 'geometries': 'polyline'},
    );
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as String?;
      if (geometry == null || geometry.isEmpty) {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }
      return DirectionsResult(
        points: _decodePolyline(geometry),
        durationSeconds: ((route['duration'] as num?) ?? 0).round(),
        distanceMeters: ((route['distance'] as num?) ?? 0).round(),
      );
    } catch (_) {
      return const DirectionsResult(points: [], durationSeconds: 0);
    }
  }

  String _formatLatLng(LatLng point) => '${point.latitude},${point.longitude}';

  int _sumLegValue(List<Map<String, dynamic>> legs, String key) {
    return legs.fold<int>(0, (sum, leg) {
      final value = leg[key] as Map<String, dynamic>?;
      return sum + (((value?['value'] as num?) ?? 0).round());
    });
  }

  List<LatLng> _decodeRoutePoints(
    Map<String, dynamic> route,
    List<Map<String, dynamic>> legs,
  ) {
    final detailed = <LatLng>[];
    for (final leg in legs) {
      final rawSteps = (leg['steps'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      for (final step in rawSteps) {
        final encoded =
            (step['polyline'] as Map<String, dynamic>?)?['points'] as String?;
        if (encoded == null || encoded.isEmpty) continue;
        _appendPolyline(detailed, _decodePolyline(encoded));
      }
    }
    if (detailed.length > 2) return detailed;

    final overview =
        (route['overview_polyline'] as Map<String, dynamic>?)?['points']
            as String?;
    return overview == null || overview.isEmpty
        ? const []
        : _decodePolyline(overview);
  }

  void _appendPolyline(List<LatLng> target, List<LatLng> points) {
    for (final point in points) {
      if (target.isNotEmpty &&
          target.last.latitude == point.latitude &&
          target.last.longitude == point.longitude) {
        continue;
      }
      target.add(point);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      final latitudeDelta = _decodeNextValue(encoded, index);
      index = latitudeDelta.nextIndex;
      lat += latitudeDelta.value;

      final longitudeDelta = _decodeNextValue(encoded, index);
      index = longitudeDelta.nextIndex;
      lng += longitudeDelta.value;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  _PolylineValue _decodeNextValue(String encoded, int startIndex) {
    var index = startIndex;
    var result = 0;
    var shift = 0;
    int byte;

    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    final value = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    return _PolylineValue(value: value, nextIndex: index);
  }
}

class _PolylineValue {
  final int value;
  final int nextIndex;

  const _PolylineValue({required this.value, required this.nextIndex});
}
