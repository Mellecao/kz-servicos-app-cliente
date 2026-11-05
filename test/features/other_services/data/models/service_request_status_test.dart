import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';

Map<String, dynamic> _json({
  String status = 'open',
  Map<String, dynamic>? provider,
  Object? finalPrice,
}) => {
  'id': 'r1',
  'service_category_id': 'cat-uuid',
  'service_categories': {'name': 'Canalizador', 'slug': 'plumber'},
  'freeform_profession': null,
  'description': 'Torneira a pingar\n\nA cozinha tem uma fuga.',
  'service_date': '2026-11-06T09:00:00+00:00',
  'observations': 'Talatona, Luanda',
  'status': status,
  'provider_profile_id': provider?['id'],
  'final_price': finalPrice,
  'provider_profiles': provider,
  'created_at': '2026-11-05T10:00:00+00:00',
};

void main() {
  group('ServiceRequestStatus', () {
    test('conhece os 10 estados reais da base de dados', () {
      const db = [
        'open',
        'under_review',
        'review_rejected',
        'searching_provider',
        'awaiting_client_confirmation',
        'awaiting_provider_confirmation',
        'assigned',
        'in_progress',
        'finished',
        'cancelled',
      ];
      for (final value in db) {
        expect(ServiceRequestStatus.fromDb(value).dbValue, value);
      }
      expect(ServiceRequestStatus.values.length, 10);
    });

    test('rótulos em pt-AO', () {
      expect(ServiceRequestStatus.open.label, 'Pedido enviado');
      expect(ServiceRequestStatus.underReview.label, 'Em análise');
      expect(ServiceRequestStatus.reviewRejected.label, 'Pedido recusado');
      expect(
        ServiceRequestStatus.searchingProvider.label,
        'À procura de profissional',
      );
      expect(
        ServiceRequestStatus.awaitingClientConfirmation.label,
        'Aguarda a sua confirmação',
      );
      expect(
        ServiceRequestStatus.awaitingProviderConfirmation.label,
        'A aguardar o prestador',
      );
      expect(ServiceRequestStatus.assigned.label, 'Prestador atribuído');
      expect(ServiceRequestStatus.inProgress.label, 'Em curso');
      expect(ServiceRequestStatus.finished.label, 'Concluído');
      expect(ServiceRequestStatus.cancelled.label, 'Cancelado');
    });

    test('valor desconhecido cai em "open"', () {
      expect(ServiceRequestStatus.fromDb('xpto'), ServiceRequestStatus.open);
    });

    test('só o cliente confirma em awaiting_client_confirmation', () {
      for (final s in ServiceRequestStatus.values) {
        expect(
          s.canAccept,
          s == ServiceRequestStatus.awaitingClientConfirmation,
          reason: s.dbValue,
        );
      }
    });

    test('cancelável antes de começar; final não', () {
      expect(ServiceRequestStatus.open.canCancel, isTrue);
      expect(ServiceRequestStatus.searchingProvider.canCancel, isTrue);
      expect(ServiceRequestStatus.awaitingClientConfirmation.canCancel, isTrue);
      expect(ServiceRequestStatus.awaitingProviderConfirmation.canCancel, isTrue);
      expect(ServiceRequestStatus.assigned.canCancel, isTrue);
      expect(ServiceRequestStatus.inProgress.canCancel, isFalse);
      expect(ServiceRequestStatus.finished.canCancel, isFalse);
      expect(ServiceRequestStatus.cancelled.canCancel, isFalse);
      expect(ServiceRequestStatus.reviewRejected.canCancel, isFalse);
    });

    test('estados finais', () {
      expect(ServiceRequestStatus.finished.isFinal, isTrue);
      expect(ServiceRequestStatus.cancelled.isFinal, isTrue);
      expect(ServiceRequestStatus.reviewRejected.isFinal, isTrue);
      expect(ServiceRequestStatus.inProgress.isFinal, isFalse);
    });

    test('chat disponível quando há prestador atribuído ou a confirmar', () {
      expect(ServiceRequestStatus.awaitingProviderConfirmation.hasChat, isTrue);
      expect(ServiceRequestStatus.assigned.hasChat, isTrue);
      expect(ServiceRequestStatus.inProgress.hasChat, isTrue);
      expect(ServiceRequestStatus.finished.hasChat, isTrue);
      expect(ServiceRequestStatus.open.hasChat, isFalse);
      expect(ServiceRequestStatus.awaitingClientConfirmation.hasChat, isFalse);
      expect(ServiceRequestStatus.cancelled.hasChat, isFalse);
    });

    test('etapa de progresso: assigned → in_progress → finished', () {
      expect(ServiceRequestStatus.assigned.progressStep, 0);
      expect(ServiceRequestStatus.inProgress.progressStep, 1);
      expect(ServiceRequestStatus.finished.progressStep, 2);
      expect(ServiceRequestStatus.open.progressStep, -1);
    });
  });

  group('ServiceRequest.fromJson', () {
    test('lê categoria (slug), estado, prestador e preço final', () {
      final r = ServiceRequest.fromJson(
        _json(
          status: 'awaiting_client_confirmation',
          finalPrice: '15000.00',
          provider: {
            'id': 'pp1',
            'user_id': 'u9',
            'average_rating': 4.8,
            'total_ratings': 31,
            'users': {'full_name': 'Miguel Prestador', 'avatar_url': null},
          },
        ),
      );
      expect(r.status, ServiceRequestStatus.awaitingClientConfirmation);
      expect(r.categorySlug, 'plumber');
      expect(r.categoryName, 'Canalizador');
      expect(r.problem, 'Torneira a pingar');
      expect(r.details, 'A cozinha tem uma fuga.');
      expect(r.finalPrice, 15000.0);
      expect(r.provider?.profileId, 'pp1');
      expect(r.provider?.userId, 'u9');
      expect(r.provider?.name, 'Miguel Prestador');
      expect(r.provider?.rating, 4.8);
      expect(r.provider?.totalRatings, 31);
    });

    test('sem prestador nem preço', () {
      final r = ServiceRequest.fromJson(_json());
      expect(r.provider, isNull);
      expect(r.finalPrice, isNull);
      expect(r.status, ServiceRequestStatus.open);
    });
  });
}
