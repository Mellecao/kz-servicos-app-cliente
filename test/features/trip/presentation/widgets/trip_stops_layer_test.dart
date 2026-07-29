import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_stop.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_stops_layer.dart';

void main() {
  const car = LatLng(-23.55, -46.63);
  const dest = LatLng(-23.60, -46.65);

  final stops = [
    const TripStop(
      id: 's1', stopOrder: 1,
      location: LatLng(-23.56, -46.635), address: 'Parada 1',
    ),
    const TripStop(
      id: 's2', stopOrder: 2,
      location: LatLng(-23.57, -46.640), address: 'Parada 2',
    ),
  ];

  group('TripStopsLayer.build', () {
    test('zero stops -> no stop markers, single polyline car->dest', () {
      final r = TripStopsLayer.build(
        stops: const [],
        currentStopOrder: null,
        carPosition: car,
        destination: dest,
      );
      expect(r.markers, isEmpty);
      expect(r.polylines, hasLength(1));
      expect(r.polylines.first.points, [car, dest]);
    });

    test('2 stops, currentStopOrder=1 -> 2 markers, segment car->stop1 highlighted', () {
      final r = TripStopsLayer.build(
        stops: stops,
        currentStopOrder: 1,
        carPosition: car,
        destination: dest,
      );
      expect(r.markers, hasLength(2));

      // active segment is car -> stop1
      final active = r.polylines.firstWhere(
        (p) => p.polylineId.value == 'stops_active',
      );
      expect(active.points, [car, stops[0].location]);
    });

    test('2 stops, currentStopOrder=2 -> active segment stop1->stop2', () {
      final r = TripStopsLayer.build(
        stops: stops,
        currentStopOrder: 2,
        carPosition: car,
        destination: dest,
      );
      final active = r.polylines.firstWhere(
        (p) => p.polylineId.value == 'stops_active',
      );
      expect(active.points, [stops[0].location, stops[1].location]);
    });

    test('currentStopOrder=null -> markers cinzas, sem segmento ativo', () {
      final r = TripStopsLayer.build(
        stops: stops,
        currentStopOrder: null,
        carPosition: car,
        destination: dest,
      );
      expect(r.markers, hasLength(2));
      expect(
        r.polylines.where((p) => p.polylineId.value == 'stops_active'),
        isEmpty,
      );
    });
  });
}
