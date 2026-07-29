import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/trip_stop.dart';

class TripStopsLayerResult {
  const TripStopsLayerResult({required this.markers, required this.polylines});
  final Set<Marker> markers;
  final List<Polyline> polylines;
}

/// Builds markers + polylines representing intermediate stops on the trip route.
///
/// - Each stop gets a grey marker.
/// - When [currentStopOrder] is set, the polyline segment leading to that stop
///   is highlighted (from carPosition if it's stop 1, or from the previous stop
///   otherwise).
/// - When [currentStopOrder] is null, all stops are shown as grey markers with
///   no highlighted segment.
/// - When [stops] is empty, returns a single polyline car -> destination.
class TripStopsLayer {
  const TripStopsLayer._();

  static TripStopsLayerResult build({
    required List<TripStop> stops,
    required int? currentStopOrder,
    required LatLng carPosition,
    required LatLng destination,
  }) {
    if (stops.isEmpty) {
      return TripStopsLayerResult(
        markers: const {},
        polylines: [
          Polyline(
            polylineId: const PolylineId('stops_direct'),
            points: [carPosition, destination],
            color: Colors.blueAccent,
            width: 5,
          ),
        ],
      );
    }

    final markers = <Marker>{
      for (final s in stops)
        Marker(
          markerId: MarkerId('stop_${s.stopOrder}'),
          position: s.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: 'Parada ${s.stopOrder}', snippet: s.address),
        ),
    };

    final polylines = <Polyline>[];

    if (currentStopOrder != null) {
      final activeIndex = stops.indexWhere((s) => s.stopOrder == currentStopOrder);
      if (activeIndex >= 0) {
        final origin = activeIndex == 0
            ? carPosition
            : stops[activeIndex - 1].location;
        polylines.add(Polyline(
          polylineId: const PolylineId('stops_active'),
          points: [origin, stops[activeIndex].location],
          color: Colors.blueAccent,
          width: 6,
        ));
      }
    }

    return TripStopsLayerResult(markers: markers, polylines: polylines);
  }
}
