import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/services/google_maps_js_types.dart';

class DirectionsResult {
  final List<LatLng> points;
  final int durationSeconds;

  const DirectionsResult({
    required this.points,
    required this.durationSeconds,
  });
}

class DirectionsService {
  final JsDirectionsSvc _service = JsDirectionsSvc();

  DirectionsService({dynamic client});

  Future<List<LatLng>> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final request = <String, Object>{
      'origin': <String, Object>{
        'lat': origin.latitude,
        'lng': origin.longitude,
      },
      'destination': <String, Object>{
        'lat': destination.latitude,
        'lng': destination.longitude,
      },
      'travelMode': 'DRIVING',
      if (waypoints.isNotEmpty)
        'waypoints': waypoints
            .map(
              (wp) => <String, Object>{
                'location': <String, Object>{
                  'lat': wp.latitude,
                  'lng': wp.longitude,
                },
                'stopover': true,
              },
            )
            .toList(),
    }.jsify() as JSObject;

    try {
      final response = await _service.route(request).toDart;
      final routes = response.routes.toDart;
      if (routes.isEmpty) return [];

      final path = routes[0].overviewPath.toDart;
      return path.map((p) => LatLng(p.lat(), p.lng())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<DirectionsResult> fetchRouteWithDuration({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final points = await fetchRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );
    return DirectionsResult(points: points, durationSeconds: 0);
  }
}
