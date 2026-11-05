import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_detail_cubit.dart';
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
  details: '',
  mediaPaths: const [],
  urgency: UrgencyType.now,
  status: status,
  createdAt: DateTime.utc(2026, 11, 5, 10),
  finalPrice: price,
  provider: provider,
);

void main() {
  late _MockRepo repo;
  late StreamController<void> changes;

  setUp(() {
    repo = _MockRepo();
    changes = StreamController<void>.broadcast();
    when(() => repo.requestChanges('r1')).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  ServiceRequestDetailCubit make({ServiceRequest? initial}) =>
      ServiceRequestDetailCubit(
        repository: repo,
        requestId: 'r1',
        initial: initial,
        refreshInterval: Duration.zero,
      );

  test('com pedido inicial, mostra-o logo e atualiza com os dados reais', () async {
    when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
      (_) async => _req(ServiceRequestStatus.awaitingClientConfirmation),
    );
    final cubit = make(initial: _req(ServiceRequestStatus.open, provider: null));
    expect(cubit.state.status, RequestDetailStatus.loaded);
    expect(cubit.state.request?.status, ServiceRequestStatus.open);

    await cubit.load();
    expect(
      cubit.state.request?.status,
      ServiceRequestStatus.awaitingClientConfirmation,
    );
    expect(cubit.state.request?.provider?.name, 'Miguel Prestador');
    await cubit.close();
  });

  test('sem pedido inicial: loading → loaded; erro → error com mensagem', () async {
    when(
      () => repo.fetchServiceRequestById('r1'),
    ).thenThrow(Exception('rede'));
    final cubit = make();
    expect(cubit.state.status, RequestDetailStatus.loading);
    await cubit.load();
    expect(cubit.state.status, RequestDetailStatus.error);
    expect(cubit.state.message, isNotEmpty);
    await cubit.close();
  });

  test('falha ao recarregar mantém os dados já mostrados', () async {
    var n = 0;
    when(() => repo.fetchServiceRequestById('r1')).thenAnswer((_) async {
      n++;
      if (n > 1) throw Exception('rede');
      return _req(ServiceRequestStatus.assigned);
    });
    final cubit = make();
    await cubit.load();
    changes.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.status, RequestDetailStatus.loaded);
    expect(cubit.state.request?.status, ServiceRequestStatus.assigned);
    await cubit.close();
  });

  test('evento realtime atualiza o estado (assigned → in_progress → finished)', () async {
    var step = 0;
    const seq = [
      ServiceRequestStatus.assigned,
      ServiceRequestStatus.inProgress,
      ServiceRequestStatus.finished,
    ];
    when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
      (_) async => _req(seq[step]),
    );
    final cubit = make();
    await cubit.load();
    expect(cubit.state.request?.status, ServiceRequestStatus.assigned);
    for (var i = 1; i < seq.length; i++) {
      step = i;
      changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.request?.status, seq[i]);
    }
    await cubit.close();
    expect(changes.hasListener, isFalse);
  });

  test('recarga periódica de segurança atualiza sem evento realtime', () async {
    var step = 0;
    when(() => repo.fetchServiceRequestById('r1')).thenAnswer((_) async {
      return _req(
        step == 0 ? ServiceRequestStatus.assigned : ServiceRequestStatus.inProgress,
      );
    });
    final cubit = ServiceRequestDetailCubit(
      repository: repo,
      requestId: 'r1',
      refreshInterval: const Duration(milliseconds: 30),
    );
    await cubit.load();
    step = 1;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(cubit.state.request?.status, ServiceRequestStatus.inProgress);
    await cubit.close();
  });

  group('accept', () {
    test('chama a RPC/UPDATE, recarrega e avisa', () async {
      var accepted = false;
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(
          accepted
              ? ServiceRequestStatus.awaitingProviderConfirmation
              : ServiceRequestStatus.awaitingClientConfirmation,
        ),
      );
      when(() => repo.acceptProvider('r1')).thenAnswer((_) async {
        accepted = true;
      });
      final cubit = make();
      await cubit.load();
      final ok = await cubit.accept();
      expect(ok, isTrue);
      expect(
        cubit.state.request?.status,
        ServiceRequestStatus.awaitingProviderConfirmation,
      );
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.notice, isNotNull);
      verify(() => repo.acceptProvider('r1')).called(1);
      await cubit.close();
    });

    test('0 linhas atualizadas → erro visível e ecrã recarregado', () async {
      var changed = false;
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(
          changed
              ? ServiceRequestStatus.cancelled
              : ServiceRequestStatus.awaitingClientConfirmation,
        ),
      );
      when(() => repo.acceptProvider('r1')).thenAnswer((_) async {
        changed = true; // o admin cancelou entretanto
        throw const ServiceRequestActionException('O pedido mudou de estado.');
      });
      final cubit = make();
      await cubit.load();
      final ok = await cubit.accept();
      expect(ok, isFalse);
      expect(cubit.state.actionError, 'O pedido mudou de estado.');
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.request?.status, ServiceRequestStatus.cancelled);
      await cubit.close();
    });

    test('erro genérico → mensagem em pt-AO sem detalhes técnicos', () async {
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(ServiceRequestStatus.awaitingClientConfirmation),
      );
      when(() => repo.acceptProvider('r1')).thenThrow(Exception('boom 500'));
      final cubit = make();
      await cubit.load();
      expect(await cubit.accept(), isFalse);
      expect(cubit.state.actionError, isNotNull);
      expect(cubit.state.actionError, isNot(contains('boom')));
      await cubit.close();
    });

    test('não aceita se o estado local não o permite', () async {
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(ServiceRequestStatus.assigned),
      );
      final cubit = make();
      await cubit.load();
      expect(await cubit.accept(), isFalse);
      verifyNever(() => repo.acceptProvider(any()));
      await cubit.close();
    });
  });

  group('cancel', () {
    test('cancela e mostra o estado cancelado', () async {
      var cancelled = false;
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(
          cancelled
              ? ServiceRequestStatus.cancelled
              : ServiceRequestStatus.searchingProvider,
          provider: null,
        ),
      );
      when(() => repo.cancelServiceRequest('r1')).thenAnswer((_) async {
        cancelled = true;
      });
      final cubit = make();
      await cubit.load();
      expect(await cubit.cancel(), isTrue);
      expect(cubit.state.request?.status, ServiceRequestStatus.cancelled);
      await cubit.close();
    });

    test('não cancela depois de o serviço começar', () async {
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(ServiceRequestStatus.inProgress),
      );
      final cubit = make();
      await cubit.load();
      expect(await cubit.cancel(), isFalse);
      verifyNever(() => repo.cancelServiceRequest(any()));
      await cubit.close();
    });
  });

  group('openChat', () {
    test('devolve o id da sala do prestador atribuído', () async {
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(ServiceRequestStatus.assigned),
      );
      when(
        () => repo.ensureChatRoom(
          serviceRequestId: 'r1',
          providerUserId: 'u9',
        ),
      ).thenAnswer((_) async => 'room-1');
      final cubit = make();
      await cubit.load();
      expect(await cubit.openChat(), 'room-1');
      await cubit.close();
    });

    test('sem prestador devolve null', () async {
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(ServiceRequestStatus.open, provider: null),
      );
      final cubit = make();
      await cubit.load();
      expect(await cubit.openChat(), isNull);
      await cubit.close();
    });

    test('falha ao abrir devolve null e expõe erro', () async {
      when(() => repo.fetchServiceRequestById('r1')).thenAnswer(
        (_) async => _req(ServiceRequestStatus.assigned),
      );
      when(
        () => repo.ensureChatRoom(
          serviceRequestId: 'r1',
          providerUserId: 'u9',
        ),
      ).thenThrow(Exception('x'));
      final cubit = make();
      await cubit.load();
      expect(await cubit.openChat(), isNull);
      expect(cubit.state.actionError, isNotNull);
      await cubit.close();
    });
  });
}
