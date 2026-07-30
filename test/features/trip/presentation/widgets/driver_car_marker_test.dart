import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_car_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DriverCarMarker.assetForBearing', () {
    test('bearing 0 returns car_00 (frente)', () {
      expect(
        DriverCarMarker.assetForBearing(0),
        'public/assets/sprite/car/car_00.png',
      );
    });

    test('bearing 90 returns car_03 (direita)', () {
      expect(
        DriverCarMarker.assetForBearing(90),
        'public/assets/sprite/car/car_03.png',
      );
    });

    test('bearing 180 returns car_06 (costas)', () {
      expect(
        DriverCarMarker.assetForBearing(180),
        'public/assets/sprite/car/car_06.png',
      );
    });

    test('bearing 270 returns car_09 (esquerda)', () {
      expect(
        DriverCarMarker.assetForBearing(270),
        'public/assets/sprite/car/car_09.png',
      );
    });

    test('bearing 45 rounds to car_02 (60 degrees, nearest bucket)', () {
      // 45 / 30 = 1.5 → round to 2 → car_02
      expect(
        DriverCarMarker.assetForBearing(45),
        'public/assets/sprite/car/car_02.png',
      );
    });

    test('bearing 360 wraps to car_00', () {
      expect(
        DriverCarMarker.assetForBearing(360),
        'public/assets/sprite/car/car_00.png',
      );
    });

    test('negative bearing normalizes: -90 == 270', () {
      expect(
        DriverCarMarker.assetForBearing(-90),
        'public/assets/sprite/car/car_09.png',
      );
    });

    test('bearing over 360 normalizes: 450 == 90', () {
      expect(
        DriverCarMarker.assetForBearing(450),
        'public/assets/sprite/car/car_03.png',
      );
    });

    test('all rendered car sprites are bundled as Flutter assets', () async {
      for (var index = 0; index < 12; index++) {
        final bearing = index * 30.0;
        final path = DriverCarMarker.assetForBearing(bearing);

        final data = await rootBundle.load(path);

        expect(data.lengthInBytes, greaterThan(0), reason: path);
      }
    });
  });
}
