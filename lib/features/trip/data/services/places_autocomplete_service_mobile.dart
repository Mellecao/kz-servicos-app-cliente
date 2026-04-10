import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';

class PlacesAutocompleteService {
  static const String _apiKey = 'AIzaSyChT4wSYd-b3fT7xfEvUvmgJ0QfZv7MYSE';

  final http.Client _client;

  PlacesAutocompleteService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<PlacePrediction>> fetchSuggestions({
    required String input,
    LatLng? location,
  }) async {
    if (input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': input,
      'key': _apiKey,
      'language': 'pt-BR',
      'components': 'country:br',
    };

    if (location != null) {
      params['location'] =
          '${location.latitude},${location.longitude}';
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
          .map(
            (e) => PlacePrediction.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
