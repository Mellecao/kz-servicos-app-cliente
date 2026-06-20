import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kz_servicos_app/core/maps/google_maps_api_key.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';

class PlacesAutocompleteService {
  final http.Client _client;

  PlacesAutocompleteService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<PlacePrediction>> fetchSuggestions({
    required String input,
    LatLng? location,
  }) async {
    if (input.trim().isEmpty) return [];

    final newApiResults = await _fetchNewPlacesSuggestions(
      input: input,
      location: location,
    );
    if (newApiResults.isNotEmpty) return newApiResults;

    return _fetchLegacySuggestions(input: input, location: location);
  }

  Future<List<PlacePrediction>> _fetchNewPlacesSuggestions({
    required String input,
    LatLng? location,
  }) async {
    final body = <String, dynamic>{
      'input': input,
      'includedRegionCodes': ['br'],
      'languageCode': 'pt-BR',
      if (location != null) ...{
        'origin': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'locationBias': {
          'circle': {
            'center': {
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
            'radius': 50000.0,
          },
        },
      },
    };

    final uri = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': GoogleMapsApiKey.value,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,suggestions.placePrediction.text',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List? ?? [];
      return suggestions
          .map((raw) {
            final suggestion = raw as Map<String, dynamic>;
            final prediction =
                suggestion['placePrediction'] as Map<String, dynamic>? ?? {};
            final text = prediction['text'] as Map<String, dynamic>? ?? {};
            return PlacePrediction(
              placeId: prediction['placeId'] as String? ?? '',
              description: text['text'] as String? ?? '',
              matchedSubstrings: _matchedSubstrings(text),
            );
          })
          .where((p) => p.placeId.isNotEmpty && p.description.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PlacePrediction>> _fetchLegacySuggestions({
    required String input,
    LatLng? location,
  }) async {
    if (input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': input,
      'key': GoogleMapsApiKey.value,
      'language': 'pt-BR',
      'components': 'country:br',
    };

    if (location != null) {
      params['location'] = '${location.latitude},${location.longitude}';
      params['radius'] = '50000';
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List? ?? [];
      return predictions
          .map((e) => PlacePrediction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<MatchedSubstring> _matchedSubstrings(Map<String, dynamic> text) {
    final matches = text['matches'] as List? ?? [];
    return matches
        .map((raw) {
          final match = raw as Map<String, dynamic>;
          final start = (match['startOffset'] as num?)?.toInt() ?? 0;
          final end = (match['endOffset'] as num?)?.toInt();
          if (end == null || end <= start) return null;
          return MatchedSubstring(offset: start, length: end - start);
        })
        .whereType<MatchedSubstring>()
        .toList();
  }
}
