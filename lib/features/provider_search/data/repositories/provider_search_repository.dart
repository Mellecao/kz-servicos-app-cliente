import 'package:kz_servicos_app/features/provider_search/data/models/provider_search_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Falha da busca ou do pedido direto. A [message] vem em pt-AO e pode ser
/// mostrada tal como está.
class ProviderSearchException implements Exception {
  const ProviderSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class ProviderSearchRepository {
  /// `rpc('search_service_providers')`: prestadores perto de ([lat], [lng]).
  Future<List<ProviderSearchResult>> search({
    required String categoryId,
    required double lat,
    required double lng,
    int limit = 12,
  });

  /// `rpc('client_request_service_from_provider')`: pedido direto a um
  /// prestador. Devolve o id do pedido (`searching_provider`, só esse convite).
  Future<String> requestFromProvider({
    required String providerProfileId,
    required String categoryId,
    required String description,
  });
}

typedef RpcInvoker =
    Future<dynamic> Function(String function, Map<String, dynamic> params);

class SupabaseProviderSearchRepository implements ProviderSearchRepository {
  SupabaseProviderSearchRepository({required SupabaseClient client})
    : _rpc = ((function, params) => client.rpc(function, params: params));

  /// Para testes: troca o `client.rpc` por [invoker].
  SupabaseProviderSearchRepository.withInvoker(RpcInvoker invoker)
    : _rpc = invoker;

  final RpcInvoker _rpc;

  @override
  Future<List<ProviderSearchResult>> search({
    required String categoryId,
    required double lat,
    required double lng,
    int limit = 12,
  }) async {
    try {
      final rows = await _rpc('search_service_providers', {
        'p_category_id': categoryId,
        'p_lat': lat,
        'p_lng': lng,
        'p_limit': limit,
      });
      return [
        for (final row in (rows as List<dynamic>? ?? const []))
          ProviderSearchResult.fromJson(Map<String, dynamic>.from(row as Map)),
      ];
    } on PostgrestException catch (e) {
      throw ProviderSearchException(e.message);
    } catch (_) {
      throw const ProviderSearchException(
        'Não foi possível procurar prestadores. Verifique a ligação e tente '
        'novamente.',
      );
    }
  }

  @override
  Future<String> requestFromProvider({
    required String providerProfileId,
    required String categoryId,
    required String description,
  }) async {
    try {
      final id = await _rpc('client_request_service_from_provider', {
        'p_provider_profile_id': providerProfileId,
        'p_service_category_id': categoryId,
        'p_description': description.trim(),
      });
      return id.toString();
    } on PostgrestException catch (e) {
      throw ProviderSearchException(e.message);
    } catch (_) {
      throw const ProviderSearchException(
        'Não foi possível enviar o pedido. Verifique a ligação e tente '
        'novamente.',
      );
    }
  }
}
