import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/services/marker_animator.dart';

class _FakeTicker extends Ticker {
  _FakeTicker(super.onTick);
}

class _FakeVsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => _FakeTicker(onTick);
}

void main() {
  group('MarkerAnimator.animateTo', () {
    late MarkerAnimator animator;
    late _FakeVsync vsync;
    late List<({LatLng pos, double bearing})> ticks;

    setUp(() {
      vsync = _FakeVsync();
      animator = MarkerAnimator(
        vsync: vsync,
        duration: const Duration(seconds: 5),
      );
      ticks = [];
    });

    tearDown(() => animator.dispose());

    test('interpolates linearly between two points', () {
      animator.animateTo(
        target: const LatLng(2, 4),
        bearing: 100,
        onTick: (p, b) => ticks.add((pos: p, bearing: b)),
        start: const LatLng(0, 0),
        startBearing: 0,
      );

      // Manually drive the ticker to 50% duration
      animator.debugTickAtProgress(0.5);
      expect(ticks.last.pos.latitude, closeTo(1.0, 0.001));
      expect(ticks.last.pos.longitude, closeTo(2.0, 0.001));
      expect(ticks.last.bearing, closeTo(50.0, 0.001));

      // Complete
      animator.debugTickAtProgress(1.0);
      expect(ticks.last.pos.latitude, closeTo(2.0, 0.001));
      expect(ticks.last.bearing, closeTo(100.0, 0.001));
    });

    test('bearing wrap-around picks the short path (350 -> 10 = +20)', () {
      animator.animateTo(
        target: const LatLng(0, 0),
        bearing: 10,
        onTick: (p, b) => ticks.add((pos: p, bearing: b)),
        start: const LatLng(0, 0),
        startBearing: 350,
      );

      animator.debugTickAtProgress(0.5);
      // Short path: 350 -> 360/0 -> 10 (20° total). Halfway = 360 (or 0)
      final b = ticks.last.bearing;
      final normalizedHalf = b % 360;
      expect(
        normalizedHalf < 5 || normalizedHalf > 355,
        isTrue,
        reason: 'expected ~360°/0°, got $normalizedHalf',
      );
    });

    test('new animateTo mid-animation cancels and restarts from current interpolated position', () {
      animator.animateTo(
        target: const LatLng(10, 10),
        bearing: 90,
        onTick: (p, b) => ticks.add((pos: p, bearing: b)),
        start: const LatLng(0, 0),
        startBearing: 0,
      );
      animator.debugTickAtProgress(0.5); // now at ~(5,5) bearing ~45
      final midPos = ticks.last.pos;

      // Start new animation from mid-position (implicit)
      ticks.clear();
      animator.animateTo(
        target: const LatLng(20, 20),
        bearing: 180,
        onTick: (p, b) => ticks.add((pos: p, bearing: b)),
      );
      animator.debugTickAtProgress(0.0);

      // First tick of new animation should be at ~midPos, not at (0,0)
      expect(ticks.first.pos.latitude, closeTo(midPos.latitude, 0.001));
      expect(ticks.first.pos.longitude, closeTo(midPos.longitude, 0.001));
    });

    test('dispose stops the internal controller without throwing', () {
      animator.animateTo(
        target: const LatLng(1, 1),
        bearing: 45,
        onTick: (p, b) => ticks.add((pos: p, bearing: b)),
        start: const LatLng(0, 0),
        startBearing: 0,
      );
      animator.dispose();
      // Second dispose is also a no-op
      expect(() => animator.dispose(), returnsNormally);
    });
  });
}
