import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/utils/angola_time.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('AngolaTime.fromBackend', () {
    test('adds one hour (Luanda is UTC+1)', () {
      expect(
        AngolaTime.fromBackend('2026-04-20T14:30:00.000Z'),
        DateTime.utc(2026, 4, 20, 15, 30),
      );
    });

    test('rolls over midnight into the next day', () {
      expect(
        AngolaTime.fromBackend('2026-04-20T23:30:00Z'),
        DateTime.utc(2026, 4, 21, 0, 30),
      );
    });

    test('normalizes timestamps that carry an offset', () {
      // 15:30+01:00 == 14:30Z -> 15:30 hora de Luanda
      expect(
        AngolaTime.fromBackend('2026-04-20T15:30:00+01:00'),
        DateTime.utc(2026, 4, 20, 15, 30),
      );
    });
  });

  group('AngolaTime.maybeFromBackend', () {
    test('returns null for null or empty', () {
      expect(AngolaTime.maybeFromBackend(null), isNull);
      expect(AngolaTime.maybeFromBackend(''), isNull);
    });

    test('converts a valid value', () {
      expect(
        AngolaTime.maybeFromBackend('2026-04-20T14:30:00Z'),
        DateTime.utc(2026, 4, 20, 15, 30),
      );
    });
  });

  group('AngolaTime.now', () {
    test('is expressed in Africa/Luanda (UTC+1, no daylight saving)', () {
      final now = AngolaTime.now();

      expect(now.location.name, 'Africa/Luanda');
      expect(now.timeZoneOffset, const Duration(hours: 1));
    });
  });
}
