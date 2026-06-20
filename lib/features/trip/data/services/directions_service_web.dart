import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kz_servicos_app/features/trip/data/services/google_maps_js_types.dart';

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
  final JsDirectionsSvc _directions = JsDirectionsSvc();

  DirectionsService({http.Client? client});

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
    final request =
        <String, Object>{
              'origin': _jsLatLng(origin),
              'destination': _jsLatLng(destination),
              'travelMode': 'DRIVING',
              if (waypoints.isNotEmpty)
                'waypoints': waypoints
                    .map((point) => {'location': _jsLatLng(point)})
                    .toList(),
            }.jsify()
            as JSObject;

    try {
      final response = await _directions.route(request).toDart;
      final routes = response.routes.toDart;
      if (routes.isEmpty) {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }

      final route = routes.first;
      final legs = route.legs.toDart;
      final points = _routePoints(route, legs);
      if (points.isEmpty) {
        return const DirectionsResult(points: [], durationSeconds: 0);
      }
      return DirectionsResult(
        points: points,
        durationSeconds: legs.fold<int>(
          0,
          (sum, leg) => sum + (leg.duration?.value ?? 0),
        ),
        distanceMeters: legs.fold<int>(
          0,
          (sum, leg) => sum + (leg.distance?.value ?? 0),
        ),
      );
    } catch (_) {
      return const DirectionsResult(points: [], durationSeconds: 0);
    }
  }

  Map<String, double> _jsLatLng(LatLng point) => {
    'lat': point.latitude,
    'lng': point.longitude,
  };

  List<LatLng> _routePoints(
    JsDirectionsRoute route,
    List<JsDirectionsLeg> legs,
  ) {
    final points = <LatLng>[];
    for (final leg in legs) {
      for (final step in leg.steps.toDart) {
        _appendPoints(
          points,
          step.path.toDart.map((point) => LatLng(point.lat(), point.lng())),
        );
      }
    }
    if (points.length > 2) return points;
    return route.overviewPath.toDart
        .map((point) => LatLng(point.lat(), point.lng()))
        .toList();
  }

  void _appendPoints(List<LatLng> target, Iterable<LatLng> points) {
    for (final point in points) {
      if (target.isNotEmpty &&
          target.last.latitude == point.latitude &&
          target.last.longitude == point.longitude) {
        continue;
      }
      target.add(point);
    }
  }
}
