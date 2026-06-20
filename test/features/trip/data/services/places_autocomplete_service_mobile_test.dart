import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kz_servicos_app/features/trip/data/services/places_autocomplete_service_mobile.dart';

void main() {
  group('PlacesAutocompleteService mobile', () {
    test(
      'sends origin and circular location bias when location is available',
      () async {
        Map<String, dynamic>? requestBody;
        final service = PlacesAutocompleteService(
          client: MockClient((request) async {
            expect(request.url.host, 'places.googleapis.com');
            expect(request.url.path, '/v1/places:autocomplete');
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'suggestions': [
                  {
                    'placePrediction': {
                      'placeId': 'nearby-place',
                      'text': {
                        'text': 'Rua próxima, São Paulo',
                        'matches': [
                          {'startOffset': 0, 'endOffset': 3},
                        ],
                      },
                    },
                  },
                ],
              }),
              200,
            );
          }),
        );

        final results = await service.fetchSuggestions(
          input: 'Rua',
          location: const LatLng(-23.55, -46.63),
        );

        expect(requestBody?['origin'], {
          'latitude': -23.55,
          'longitude': -46.63,
        });
        expect(requestBody?['locationBias'], {
          'circle': {
            'center': {'latitude': -23.55, 'longitude': -46.63},
            'radius': 50000.0,
          },
        });
        expect(results.single.placeId, 'nearby-place');
        expect(results.single.description, 'Rua próxima, São Paulo');
        expect(results.single.matchedSubstrings.single.length, 3);
      },
    );
  });
}
