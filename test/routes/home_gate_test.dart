import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/trips_enabled_repository.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/cubit/trips_enabled_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';
import 'package:kz_servicos_app/routes/home_gate.dart';

class _FakeTrips implements TripsEnabledRepository {
  _FakeTrips(this.result);

  final Completer<bool> result;
  int reads = 0;

  @override
  Future<bool> fetchTripsEnabled() {
    reads++;
    return result.future;
  }
}

class _ThrowingTrips implements TripsEnabledRepository {
  @override
  Future<bool> fetchTripsEnabled() async => throw Exception('rls');
}

Widget _app(TripsEnabledCubit cubit) => MaterialApp(
  home: BlocProvider.value(
    value: cubit,
    child: HomeGate(
      tripBuilder: (_) => const Text('home de viagens'),
      searchBuilder: (_) => const Text('buscar prestadores'),
    ),
  ),
);

void main() {
  testWidgets('trips_enabled=false opens "Buscar prestadores"', (tester) async {
    final repo = _FakeTrips(Completer()..complete(false));
    final cubit = TripsEnabledCubit(repository: repo);
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.text('buscar prestadores'), findsOneWidget);
    expect(find.text('home de viagens'), findsNothing);
  });

  testWidgets('trips_enabled=true keeps the original trip home', (
    tester,
  ) async {
    final repo = _FakeTrips(Completer()..complete(true));
    final cubit = TripsEnabledCubit(repository: repo);
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.text('home de viagens'), findsOneWidget);
    expect(find.text('buscar prestadores'), findsNothing);
  });

  testWidgets('shows a loader (never the wrong screen) while reading', (
    tester,
  ) async {
    final completer = Completer<bool>();
    final cubit = TripsEnabledCubit(repository: _FakeTrips(completer));
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('home de viagens'), findsNothing);
    expect(find.text('buscar prestadores'), findsNothing);

    completer.complete(false);
    await tester.pump();
    expect(find.text('buscar prestadores'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failed read falls back to "Buscar prestadores"', (
    tester,
  ) async {
    final cubit = TripsEnabledCubit(repository: _ThrowingTrips());
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.text('buscar prestadores'), findsOneWidget);
  });

  group('TripBottomNav first item', () {
    Widget nav({required bool tripsEnabled}) => MaterialApp(
      home: Scaffold(
        body: TripBottomNav(
          selectedIndex: 0,
          onItemSelected: (_) {},
          tripsEnabled: tripsEnabled,
        ),
      ),
    );

    testWidgets('is "Buscar" with a search icon when trips are off', (
      tester,
    ) async {
      await tester.pumpWidget(nav(tripsEnabled: false));
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.local_taxi_rounded), findsNothing);
    });

    testWidgets('stays "Viagens" with a taxi icon when trips are on', (
      tester,
    ) async {
      await tester.pumpWidget(nav(tripsEnabled: true));
      expect(find.byIcon(Icons.local_taxi_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsNothing);
    });
  });
}
