import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kz_servicos_app/features/trip/data/services/geocoding_address_service_mobile.dart';
import 'package:kz_servicos_app/features/trip/data/services/geocoding_service_mobile.dart';

const _luanda = LatLng(-8.8383, 13.2344);

void main() {
  group('GeocodingService mobile', () {
    test('reverse geocodes in European Portuguese biased to Angola', () async {
      Uri? uri;
      final service = GeocodingService(
        client: MockClient((request) async {
          uri = request.url;
          return http.Response('{"status":"ZERO_RESULTS","results":[]}', 200);
        }),
      );

      await service.reverseGeocode(_luanda);

      expect(uri?.path, '/maps/api/geocode/json');
      expect(uri?.queryParameters['language'], 'pt-PT');
      expect(uri?.queryParameters['region'], 'ao');
    });
  });

  group('GeocodingAddressService mobile', () {
    test('reverse geocode to address uses pt-PT and region ao', () async {
      Uri? uri;
      final service = GeocodingAddressService(
        client: MockClient((request) async {
          uri = request.url;
          return http.Response('{"status":"ZERO_RESULTS","results":[]}', 200);
        }),
      );

      await service.reverseGeocodeToAddress(_luanda);

      expect(uri?.queryParameters['language'], 'pt-PT');
      expect(uri?.queryParameters['region'], 'ao');
    });

    test('place id lookup uses pt-PT and region ao', () async {
      Uri? uri;
      final service = GeocodingAddressService(
        client: MockClient((request) async {
          uri = request.url;
          return http.Response('{"status":"ZERO_RESULTS","results":[]}', 200);
        }),
      );

      await service.getAddressFromPlaceId('place-id');

      expect(uri?.queryParameters['place_id'], 'place-id');
      expect(uri?.queryParameters['language'], 'pt-PT');
      expect(uri?.queryParameters['region'], 'ao');
    });
  });
}
