import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_detail_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/pages/request_detail_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ServiceRequestRepository {}

const _provider = ServiceProvider(
  profileId: 'pp1',
  userId: 'u9',
  name: 'Miguel Prestador',
  rating: 4.8,
  totalRatings: 31,
);

ServiceRequest _req(
  ServiceRequestStatus status, {
  ServiceProvider? provider = _provider,
  double? price = 15000,
}) => ServiceRequest(
  id: 'r1',
  categoryId: 'c1',
  categorySlug: 'plumber',
  categoryName: 'Canalizador',
  problem: 'Torneira a pingar',
  details: 'A cozinha tem uma fuga.',
  mediaPaths: const [],
  urgency: UrgencyType.now,
  status: status,
  createdAt: DateTime.utc(2026, 11, 5, 10),
  finalPrice: price,
  provider: provider,
);

/// A página tem uma animação de pulsação infinita: `pumpAndSettle` nunca
/// assentaria. Avança o tempo o suficiente para animações e futuros.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late _MockRepo repo;
  late StreamController<void> changes;

  setUp(() {
    repo = _MockRepo();
    changes = StreamController<void>.broadcast();
    when(() => repo.requestChanges('r1')).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  Future<void> pump(WidgetTester tester, ServiceRequestStatus status) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
      (_) async => _req(
        status,
        provider: status == ServiceRequestStatus.open ||
                status == ServiceRequestStatus.searchingProvider
            ? null
            : _provider,
      ),
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => BlocProvider(
                create: (_) => ServiceRequestDetailCubit(
                  repository: repo,
                  requestId: 'r1',
                  refreshInterval: Duration.zero,
                )..load(),
                child: const RequestDetailPage(),
              ),
            ),
            GoRoute(
              path: '/chat/:id',
              builder: (_, s) => Text('chat ${s.pathParameters['id']}'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('à procura: painel de espera e botão de cancelar, sem prestador', (
    tester,
  ) async {
    await pump(tester, ServiceRequestStatus.searchingProvider);
    expect(find.text('À procura de um profissional disponível...'), findsOneWidget);
    expect(find.byKey(const Key('service_provider_card')), findsNothing);
    expect(find.byKey(const Key('service_cancel')), findsOneWidget);
    expect(find.byKey(const Key('service_accept')), findsNothing);
  });

  testWidgets('aguarda confirmação do cliente: prestador, preço em Kz e Aceitar', (
    tester,
  ) async {
    await pump(tester, ServiceRequestStatus.awaitingClientConfirmation);
    expect(find.text('Miguel Prestador'), findsOneWidget);
    expect(find.text('15.000,00 Kz'), findsOneWidget);
    expect(find.text('4,8 ★ · 31 avaliações'), findsOneWidget);
    expect(find.byKey(const Key('service_accept')), findsOneWidget);
    expect(find.byKey(const Key('service_cancel')), findsOneWidget);
  });

  testWidgets('Aceitar chama o repositório e passa a aguardar o prestador', (
    tester,
  ) async {
    var accepted = false;
    when(() => repo.acceptProvider('r1')).thenAnswer((_) async {
      accepted = true;
    });
    await pump(tester, ServiceRequestStatus.awaitingClientConfirmation);
    when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
      (_) async => _req(
        accepted
            ? ServiceRequestStatus.awaitingProviderConfirmation
            : ServiceRequestStatus.awaitingClientConfirmation,
      ),
    );

    await tester.tap(find.byKey(const Key('service_accept')));
    await settle(tester);

    verify(() => repo.acceptProvider('r1')).called(1);
    expect(find.text('A aguardar confirmação do prestador'), findsOneWidget);
    expect(find.byKey(const Key('service_accept')), findsNothing);
  });

  testWidgets('Aceitar com 0 linhas atualizadas mostra o erro ao utilizador', (
    tester,
  ) async {
    when(() => repo.acceptProvider('r1')).thenThrow(
      const ServiceRequestActionException('O pedido mudou de estado.'),
    );
    await pump(tester, ServiceRequestStatus.awaitingClientConfirmation);

    await tester.tap(find.byKey(const Key('service_accept')));
    await settle(tester);

    expect(find.text('O pedido mudou de estado.'), findsOneWidget);
  });

  testWidgets('Cancelar: confirma no diálogo e chama o repositório', (
    tester,
  ) async {
    var cancelled = false;
    when(() => repo.cancelServiceRequest('r1')).thenAnswer((_) async {
      cancelled = true;
    });
    await pump(tester, ServiceRequestStatus.awaitingClientConfirmation);
    when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
      (_) async => _req(
        cancelled
            ? ServiceRequestStatus.cancelled
            : ServiceRequestStatus.awaitingClientConfirmation,
      ),
    );

    await tester.tap(find.byKey(const Key('service_cancel')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('service_cancel_confirm')));
    await settle(tester);

    verify(() => repo.cancelServiceRequest('r1')).called(1);
    expect(tester.takeException(), isNull);
    expect(find.text('Pedido cancelado'), findsOneWidget);
    expect(find.byKey(const Key('service_cancel')), findsNothing);
  });

  testWidgets('atribuído: linha de progresso, prestador, chat; muda em tempo real', (
    tester,
  ) async {
    await pump(tester, ServiceRequestStatus.assigned);
    expect(find.byKey(const Key('service_timeline')), findsOneWidget);
    expect(find.text('Miguel Prestador'), findsOneWidget);
    expect(find.byKey(const Key('service_open_chat')), findsOneWidget);
    expect(find.text('O prestador confirmou. Combine os detalhes pelo chat.'), findsOneWidget);

    when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
      (_) async => _req(ServiceRequestStatus.inProgress),
    );
    changes.add(null);
    await settle(tester);
    expect(find.text('O serviço está em curso.'), findsOneWidget);
    expect(find.byKey(const Key('service_cancel')), findsNothing);

    when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
      (_) async => _req(ServiceRequestStatus.finished),
    );
    changes.add(null);
    await settle(tester);
    expect(find.textContaining('Serviço concluído'), findsOneWidget);
  });

  testWidgets('abrir conversa navega para /chat/<sala>', (tester) async {
    when(
      () => repo.ensureChatRoom(serviceRequestId: 'r1', providerUserId: 'u9'),
    ).thenAnswer((_) async => 'room-7');
    await pump(tester, ServiceRequestStatus.assigned);

    await tester.tap(find.byKey(const Key('service_open_chat')));
    await settle(tester);

    expect(find.text('chat room-7'), findsOneWidget);
  });

  testWidgets('cancelado e recusado: aviso e sem ações', (tester) async {
    await pump(tester, ServiceRequestStatus.cancelled);
    expect(find.text('Pedido cancelado'), findsOneWidget);
    expect(find.byKey(const Key('service_cancel')), findsNothing);
    expect(find.byKey(const Key('service_accept')), findsNothing);
  });

  testWidgets('erro de carregamento mostra "Tentar novamente"', (tester) async {
    when(() => repo.fetchServiceRequestById('r1')).thenThrow(Exception('rede'));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => ServiceRequestDetailCubit(
            repository: repo,
            requestId: 'r1',
            refreshInterval: Duration.zero,
          )..load(),
          child: const RequestDetailPage(),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Erro ao carregar o pedido'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
