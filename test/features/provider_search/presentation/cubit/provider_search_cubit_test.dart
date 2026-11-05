import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/provider_search/data/models/provider_search_result.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/provider_search_repository.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/cubit/provider_search_cubit.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/cubit/provider_search_state.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/cubit/trips_enabled_cubit.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/trips_enabled_repository.dart';

const _plumber = ServiceCategory(
  id: 'c-plumber',
  name: 'Canalizador',
  slug: 'plumber',
  icon: Icons.plumbing,
  color: Colors.blue,
);

const _electrician = ServiceCategory(
  id: 'c-electrician',
  name: 'Eletricista',
  slug: 'electrician',
  icon: Icons.electrical_services,
  color: Colors.amber,
);

ProviderSearchResult _provider(String id, {String category = 'c-plumber'}) =>
    ProviderSearchResult(
      providerProfileId: id,
      fullName: 'Prestador $id',
      categoryId: category,
      categoryName: 'Canalizador',
      priceMin: 5500,
      priceMax: 38500,
      avgResponseMinutes: 18,
      lat: -8.84,
      lng: 13.23,
    );

class _FakeRepository implements ProviderSearchRepository {
  _FakeRepository({this.onSearch, this.onRequest});

  Future<List<ProviderSearchResult>> Function(String categoryId)? onSearch;
  Future<String> Function(String providerId, String description)? onRequest;
  final searched = <String>[];

  @override
  Future<List<ProviderSearchResult>> search({
    required String categoryId,
    required double lat,
    required double lng,
    int limit = 12,
  }) {
    searched.add(categoryId);
    return onSearch!(categoryId);
  }

  @override
  Future<String> requestFromProvider({
    required String providerProfileId,
    required String categoryId,
    required String description,
  }) => onRequest!(providerProfileId, description);
}

void main() {
  group('ProviderSearchCubit.search', () {
    blocTest<ProviderSearchCubit, ProviderSearchState>(
      'emits searching and then the providers',
      build: () => ProviderSearchCubit(
        repository: _FakeRepository(
          onSearch: (_) async => [_provider('a'), _provider('b')],
        ),
        minSearchDuration: Duration.zero,
      ),
      act: (c) => c.search(_plumber, lat: -8.8, lng: 13.2),
      expect: () => [
        const ProviderSearchSearching(_plumber),
        ProviderSearchResults(_plumber, [_provider('a'), _provider('b')]),
      ],
    );

    blocTest<ProviderSearchCubit, ProviderSearchState>(
      'a category without providers is a normal (empty) result',
      build: () => ProviderSearchCubit(
        repository: _FakeRepository(onSearch: (_) async => const []),
        minSearchDuration: Duration.zero,
      ),
      act: (c) => c.search(_plumber, lat: 0, lng: 0),
      expect: () => [
        const ProviderSearchSearching(_plumber),
        const ProviderSearchResults(_plumber, []),
      ],
    );

    blocTest<ProviderSearchCubit, ProviderSearchState>(
      'a server error becomes a failure with the server message',
      build: () => ProviderSearchCubit(
        repository: _FakeRepository(
          onSearch: (_) async =>
              throw const ProviderSearchException('Sem rede'),
        ),
        minSearchDuration: Duration.zero,
      ),
      act: (c) => c.search(_plumber, lat: 0, lng: 0),
      expect: () => [
        const ProviderSearchSearching(_plumber),
        const ProviderSearchFailure(_plumber, 'Sem rede'),
      ],
    );

    blocTest<ProviderSearchCubit, ProviderSearchState>(
      'an unexpected error becomes a friendly failure',
      build: () => ProviderSearchCubit(
        repository: _FakeRepository(
          onSearch: (_) async => throw StateError('x'),
        ),
        minSearchDuration: Duration.zero,
      ),
      act: (c) => c.search(_plumber, lat: 0, lng: 0),
      expect: () => [
        const ProviderSearchSearching(_plumber),
        isA<ProviderSearchFailure>().having(
          (s) => s.message,
          'message',
          contains('prestadores'),
        ),
      ],
    );

    test('keeps the searching state for at least minSearchDuration', () async {
      final cubit = ProviderSearchCubit(
        repository: _FakeRepository(onSearch: (_) async => [_provider('a')]),
        minSearchDuration: const Duration(milliseconds: 300),
      );
      addTearDown(cubit.close);
      final watch = Stopwatch()..start();

      await cubit.search(_plumber, lat: 0, lng: 0);

      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(290));
      expect(cubit.state, isA<ProviderSearchResults>());
    });

    test('a slow answer for an old category is ignored', () async {
      final slow = Completer<List<ProviderSearchResult>>();
      final repo = _FakeRepository(
        onSearch: (id) => id == 'c-plumber'
            ? slow.future
            : Future.value([_provider('e1', category: 'c-electrician')]),
      );
      final cubit = ProviderSearchCubit(
        repository: repo,
        minSearchDuration: Duration.zero,
      );
      addTearDown(cubit.close);

      final first = cubit.search(_plumber, lat: 0, lng: 0);
      await cubit.search(_electrician, lat: 0, lng: 0);
      slow.complete([_provider('p1')]);
      await first;

      final state = cubit.state as ProviderSearchResults;
      expect(state.category, _electrician);
      expect(state.providers.single.providerProfileId, 'e1');
    });

    blocTest<ProviderSearchCubit, ProviderSearchState>(
      'reset goes back to idle',
      build: () => ProviderSearchCubit(
        repository: _FakeRepository(onSearch: (_) async => [_provider('a')]),
        minSearchDuration: Duration.zero,
      ),
      act: (c) async {
        await c.search(_plumber, lat: 0, lng: 0);
        c.reset();
      },
      skip: 2,
      expect: () => [const ProviderSearchIdle()],
    );
  });

  group('ProviderSearchCubit.requestService', () {
    test('returns the new request id', () async {
      final cubit = ProviderSearchCubit(
        repository: _FakeRepository(
          onRequest: (provider, description) async => 'req-1',
        ),
        minSearchDuration: Duration.zero,
      );
      addTearDown(cubit.close);

      expect(
        await cubit.requestService(
          provider: _provider('a'),
          description: 'Torneira a pingar',
        ),
        'req-1',
      );
    });

    test('rejects a blank description without calling the server', () async {
      var called = false;
      final cubit = ProviderSearchCubit(
        repository: _FakeRepository(
          onRequest: (_, _) async {
            called = true;
            return 'x';
          },
        ),
        minSearchDuration: Duration.zero,
      );
      addTearDown(cubit.close);

      await expectLater(
        cubit.requestService(provider: _provider('a'), description: '   '),
        throwsA(
          isA<ProviderSearchException>().having(
            (e) => e.message,
            'message',
            contains('Descreva'),
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('lets the server message through', () async {
      final cubit = ProviderSearchCubit(
        repository: _FakeRepository(
          onRequest: (_, _) async =>
              throw const ProviderSearchException('Prestador indisponível'),
        ),
        minSearchDuration: Duration.zero,
      );
      addTearDown(cubit.close);

      await expectLater(
        cubit.requestService(provider: _provider('a'), description: 'x'),
        throwsA(
          isA<ProviderSearchException>().having(
            (e) => e.message,
            'message',
            'Prestador indisponível',
          ),
        ),
      );
    });
  });

  group('TripsEnabledCubit', () {
    blocTest<TripsEnabledCubit, TripsEnabledState>(
      'starts loading and becomes enabled',
      build: () => TripsEnabledCubit(repository: _FakeTrips(() async => true)),
      act: (c) => c.load(),
      expect: () => [TripsEnabledState.enabled],
    );

    blocTest<TripsEnabledCubit, TripsEnabledState>(
      'becomes disabled when the switch is off',
      build: () => TripsEnabledCubit(repository: _FakeTrips(() async => false)),
      act: (c) => c.load(),
      expect: () => [TripsEnabledState.disabled],
    );

    blocTest<TripsEnabledCubit, TripsEnabledState>(
      'a failed read counts as disabled',
      build: () => TripsEnabledCubit(
        repository: _FakeTrips(() async => throw Exception('rls')),
      ),
      act: (c) => c.load(),
      expect: () => [TripsEnabledState.disabled],
    );

    test('starts in the loading state', () {
      final cubit = TripsEnabledCubit(
        repository: _FakeTrips(() async => false),
      );
      addTearDown(cubit.close);
      expect(cubit.state, TripsEnabledState.loading);
    });

    test('keeps the current value while reloading', () async {
      var value = true;
      final cubit = TripsEnabledCubit(
        repository: _FakeTrips(() async => value),
      );
      addTearDown(cubit.close);
      await cubit.load();
      final seen = <TripsEnabledState>[];
      final sub = cubit.stream.listen(seen.add);

      value = false;
      await cubit.load();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen, [TripsEnabledState.disabled]);
    });
  });
}

class _FakeTrips implements TripsEnabledRepository {
  _FakeTrips(this._read);

  final Future<bool> Function() _read;

  @override
  Future<bool> fetchTripsEnabled() => _read();
}
