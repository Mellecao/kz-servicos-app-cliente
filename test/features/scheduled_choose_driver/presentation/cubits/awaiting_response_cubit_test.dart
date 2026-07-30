import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/pages/awaiting_driver_response_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduledDirectRequestRepository extends Mock
    implements ScheduledDirectRequestRepository {}

void main() {
  late _MockScheduledDirectRequestRepository repository;
  late AwaitingResponseCubit cubit;

  setUp(() {
    repository = _MockScheduledDirectRequestRepository();
    cubit = AwaitingResponseCubit(tripId: 'trip-1', repo: repository);
  });

  tearDown(() => cubit.close());

  test(
    'ignora um segundo cancelamento enquanto o primeiro está em andamento',
    () async {
      final cancellation = Completer<void>();
      when(
        () => repository.cancel('trip-1', any()),
      ).thenAnswer((_) => cancellation.future);

      final firstCall = cubit.cancel('');
      final secondCall = cubit.cancel('');
      cancellation.complete();

      await Future.wait([firstCall, secondCall]);

      verify(() => repository.cancel('trip-1', '')).called(1);
      expect(cubit.state.status, ScheduledDirectStatus.cancelled);
    },
  );

  testWidgets('volta para o início quando a solicitação é cancelada', (
    tester,
  ) async {
    when(() => repository.cancel('trip-1', any())).thenAnswer((_) async {});

    final router = GoRouter(
      initialLocation: '/awaiting',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Início')),
        ),
        GoRoute(
          path: '/awaiting',
          builder: (_, _) => BlocProvider.value(
            value: cubit,
            child: const AwaitingDriverResponsePage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await cubit.cancel('');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Início'), findsOneWidget);
  });
}
