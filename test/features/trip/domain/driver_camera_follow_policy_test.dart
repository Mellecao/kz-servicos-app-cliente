import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/driver_camera_follow_policy.dart';

void main() {
  group('DriverCameraFollowPolicy', () {
    test('mantém um zoom próximo para centralizar o motorista', () {
      expect(DriverCameraFollowPolicy.zoom, greaterThanOrEqualTo(17));
    });

    test('limita a frequência das animações da câmera', () {
      final lastUpdate = DateTime(2026, 7, 29, 12);

      expect(
        DriverCameraFollowPolicy.shouldUpdate(
          lastUpdate: lastUpdate,
          now: lastUpdate.add(
            DriverCameraFollowPolicy.minimumUpdateInterval -
                const Duration(milliseconds: 1),
          ),
        ),
        isFalse,
      );
      expect(
        DriverCameraFollowPolicy.shouldUpdate(
          lastUpdate: lastUpdate,
          now: lastUpdate.add(DriverCameraFollowPolicy.minimumUpdateInterval),
        ),
        isTrue,
      );
    });

    test('permite a primeira centralização imediatamente', () {
      expect(
        DriverCameraFollowPolicy.shouldUpdate(
          lastUpdate: null,
          now: DateTime(2026, 7, 29, 12),
        ),
        isTrue,
      );
    });
  });
}
