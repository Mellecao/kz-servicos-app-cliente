import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/trips_enabled_repository.dart';

void main() {
  group('parseTripsEnabled', () {
    test('only an explicit true turns trips on', () {
      expect(parseTripsEnabled(true), isTrue);
      expect(parseTripsEnabled('true'), isTrue);
    });

    test('everything else is off', () {
      expect(parseTripsEnabled(false), isFalse);
      expect(parseTripsEnabled('false'), isFalse);
      expect(parseTripsEnabled(null), isFalse);
      expect(parseTripsEnabled(1), isFalse);
      expect(parseTripsEnabled({'enabled': true}), isFalse);
    });
  });

  group('SupabaseTripsEnabledRepository', () {
    test('reads the setting value', () async {
      final repo = SupabaseTripsEnabledRepository.withReader(() async => true);
      expect(await repo.fetchTripsEnabled(), isTrue);
    });

    test('a missing row means off', () async {
      final repo = SupabaseTripsEnabledRepository.withReader(() async => null);
      expect(await repo.fetchTripsEnabled(), isFalse);
    });

    test('a failed read means off', () async {
      final repo = SupabaseTripsEnabledRepository.withReader(
        () async => throw Exception('rls'),
      );
      expect(await repo.fetchTripsEnabled(), isFalse);
    });
  });
}
