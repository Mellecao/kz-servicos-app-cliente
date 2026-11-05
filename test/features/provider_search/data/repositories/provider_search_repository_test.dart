import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/provider_search_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _row(String id) => {
  'provider_profile_id': id,
  'full_name': 'Prestador $id',
  'avatar_url': null,
  'bio': null,
  'category_id': 'c-1',
  'category_name': 'Canalizador',
  'average_rating': 4.5,
  'total_ratings': 10,
  'price_min': 5500,
  'price_max': 38500,
  'avg_response_minutes': 18,
  'is_demo': true,
  'lat': -8.84,
  'lng': 13.23,
  'distance_m': 500,
};

void main() {
  late List<({String fn, Map<String, dynamic> params})> calls;

  SupabaseProviderSearchRepository repo(
    Future<dynamic> Function(String fn, Map<String, dynamic> params) handler,
  ) {
    calls = [];
    return SupabaseProviderSearchRepository.withInvoker((fn, params) {
      calls.add((fn: fn, params: params));
      return handler(fn, params);
    });
  }

  group('search', () {
    test('calls search_service_providers with the client position', () async {
      final r = repo((_, _) async => [_row('a'), _row('b')]);

      final result = await r.search(categoryId: 'c-1', lat: -8.8, lng: 13.2);

      expect(calls.single.fn, 'search_service_providers');
      expect(calls.single.params, {
        'p_category_id': 'c-1',
        'p_lat': -8.8,
        'p_lng': 13.2,
        'p_limit': 12,
      });
      expect(result.map((p) => p.providerProfileId), ['a', 'b']);
      expect(result.first.isDemo, isTrue);
    });

    test('returns an empty list when the category has no providers', () async {
      final r = repo((_, _) async => <dynamic>[]);
      expect(await r.search(categoryId: 'c', lat: 0, lng: 0), isEmpty);
    });

    test('turns a server error into a ProviderSearchException', () async {
      final r = repo(
        (_, _) async => throw const PostgrestException(
          message: 'Sessão inválida. Inicie sessão novamente.',
        ),
      );
      await expectLater(
        r.search(categoryId: 'c', lat: 0, lng: 0),
        throwsA(
          isA<ProviderSearchException>().having(
            (e) => e.message,
            'message',
            'Sessão inválida. Inicie sessão novamente.',
          ),
        ),
      );
    });

    test('uses a friendly message for unexpected failures', () async {
      final r = repo((_, _) async => throw Exception('socket closed'));
      await expectLater(
        r.search(categoryId: 'c', lat: 0, lng: 0),
        throwsA(
          isA<ProviderSearchException>().having(
            (e) => e.message,
            'message',
            allOf(contains('prestadores'), isNot(contains('socket'))),
          ),
        ),
      );
    });
  });

  group('requestFromProvider', () {
    test(
      'calls client_request_service_from_provider and returns the id',
      () async {
        final r = repo((_, _) async => 'req-123');

        final id = await r.requestFromProvider(
          providerProfileId: 'p-1',
          categoryId: 'c-1',
          description: '  Torneira a pingar  ',
        );

        expect(id, 'req-123');
        expect(calls.single.fn, 'client_request_service_from_provider');
        expect(calls.single.params, {
          'p_provider_profile_id': 'p-1',
          'p_service_category_id': 'c-1',
          'p_description': 'Torneira a pingar',
        });
      },
    );

    test('shows the server message as it comes (already pt-AO)', () async {
      final r = repo(
        (_, _) async => throw const PostgrestException(
          message:
              'Já enviou um pedido a este prestador. Aguarde a proposta dele',
        ),
      );
      await expectLater(
        r.requestFromProvider(
          providerProfileId: 'p',
          categoryId: 'c',
          description: 'x',
        ),
        throwsA(
          isA<ProviderSearchException>().having(
            (e) => e.message,
            'message',
            'Já enviou um pedido a este prestador. Aguarde a proposta dele',
          ),
        ),
      );
    });

    test('uses a friendly message for unexpected failures', () async {
      final r = repo((_, _) async => throw Exception('boom'));
      await expectLater(
        r.requestFromProvider(
          providerProfileId: 'p',
          categoryId: 'c',
          description: 'x',
        ),
        throwsA(
          isA<ProviderSearchException>().having(
            (e) => e.message,
            'message',
            contains('pedido'),
          ),
        ),
      );
    });
  });
}
