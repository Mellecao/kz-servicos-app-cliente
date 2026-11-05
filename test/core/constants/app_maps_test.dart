import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_maps.dart';

void main() {
  group('AppMaps', () {
    test('default center is Luanda', () {
      expect(AppMaps.defaultCenter, const LatLng(-8.8383, 13.2344));
    });

    test('restricts Google services to Angola in European Portuguese', () {
      expect(AppMaps.regionCode, 'ao');
      expect(AppMaps.languageCode, 'pt-PT');
      expect(AppMaps.placesComponents, 'country:ao');
    });
  });
}
