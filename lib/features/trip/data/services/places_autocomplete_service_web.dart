import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/data/services/google_maps_js_types.dart';

class PlacesAutocompleteService {
  PlacesAutocompleteService({dynamic client});

  Future<List<PlacePrediction>> fetchSuggestions({
    required String input,
    LatLng? location,
  }) async {
    if (input.trim().isEmpty) return [];

    final params = <String, Object>{
      'input': input,
      'includedRegionCodes': ['br'],
      'language': 'pt-BR',
    };

    if (location != null) {
      params['origin'] = <String, Object>{
        'lat': location.latitude,
        'lng': location.longitude,
      };
      params['locationBias'] = <String, Object>{
        'center': <String, Object>{
          'lat': location.latitude,
          'lng': location.longitude,
        },
        'radius': 50000.0,
      };
    }

    try {
      final request = params.jsify() as JSObject;
      final response =
          await JsAutocompleteSuggestion.fetchAutocompleteSuggestions(
        request,
      ).toDart;
      final suggestions = response.suggestions.toDart;

      return suggestions.map((s) {
        final pred = s.placePrediction;
        final matchList = <MatchedSubstring>[];
        try {
          final matches = pred.text.matches.toDart;
          for (final m in matches) {
            final offset = m.offset;
            final length = m.length;
            if (offset != null && length != null) {
              matchList.add(
                MatchedSubstring(offset: offset, length: length),
              );
            }
          }
        } catch (_) {}
        return PlacePrediction(
          placeId: pred.placeId,
          description: pred.text.text,
          matchedSubstrings: matchList,
        );
      }).toList();
    } catch (e) {
      debugPrint('[KZ] AutocompleteSuggestion error: $e');
      return [];
    }
  }
}
