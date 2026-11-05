import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kz_servicos_app/features/trip/data/services/directions_service_mobile.dart';

const _googleDirectionsResponse = '''
{
  "status": "OK",
  "routes": [
    {
      "overview_polyline": {
        "points": "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
      },
      "legs": [
        {
          "duration": { "value": 123 },
          "distance": { "value": 5678 }
        },
        {
          "duration": { "value": 50 },
          "distance": { "value": 1000 }
        }
      ]
    }
  ]
}
''';

void main() {
  group('DirectionsService mobile', () {
    test('uses Google Directions and decodes overview polyline', () async {
      Uri? requestedUri;
      final service = DirectionsService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(_googleDirectionsResponse, 200);
        }),
      );

      final result = await service.fetchRouteWithDuration(
        origin: const LatLng(10, 20),
        destination: const LatLng(30, 40),
        waypoints: const [LatLng(15, 25)],
      );

      expect(requestedUri!.host, 'maps.googleapis.com');
      expect(requestedUri!.path, '/maps/api/directions/json');
      expect(requestedUri!.queryParameters['origin'], '10.0,20.0');
      expect(requestedUri!.queryParameters['destination'], '30.0,40.0');
      expect(requestedUri!.queryParameters['waypoints'], '15.0,25.0');
      expect(requestedUri!.queryParameters['mode'], 'driving');
      expect(requestedUri!.queryParameters['language'], 'pt-PT');
      expect(requestedUri!.queryParameters['region'], 'ao');
      expect(result.points, const [
        LatLng(38.5, -120.2),
        LatLng(40.7, -120.95),
        LatLng(43.252, -126.453),
      ]);
      expect(result.durationSeconds, 173);
      expect(result.distanceMeters, 6678);
    });
  });
}
