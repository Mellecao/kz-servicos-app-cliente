import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/provider_search/data/models/provider_search_result.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/provider_search_repository.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/cubit/provider_search_state.dart';

class ProviderSearchCubit extends Cubit<ProviderSearchState> {
  ProviderSearchCubit({
    required ProviderSearchRepository repository,
    this.minSearchDuration = const Duration(milliseconds: 2500),
  }) : _repository = repository,
       super(const ProviderSearchIdle());

  final ProviderSearchRepository _repository;

  /// Tempo mínimo da animação "a procurar…", mesmo que a resposta chegue antes.
  final Duration minSearchDuration;

  int _generation = 0;

  /// Procura prestadores da [category] perto de ([lat], [lng]).
  Future<void> search(
    ServiceCategory category, {
    required double lat,
    required double lng,
  }) async {
    final generation = ++_generation;
    emit(ProviderSearchSearching(category));
    try {
      final results = await Future.wait<Object>([
        _repository.search(categoryId: category.id, lat: lat, lng: lng),
        Future<void>.delayed(minSearchDuration).then((_) => Object()),
      ]);
      if (generation != _generation || isClosed) return;
      emit(
        ProviderSearchResults(
          category,
          results.first as List<ProviderSearchResult>,
        ),
      );
    } on ProviderSearchException catch (e) {
      if (generation != _generation || isClosed) return;
      emit(ProviderSearchFailure(category, e.message));
    } catch (_) {
      if (generation != _generation || isClosed) return;
      emit(
        ProviderSearchFailure(
          category,
          'Não foi possível procurar prestadores. Tente novamente.',
        ),
      );
    }
  }

  /// Volta ao estado inicial e ignora qualquer procura em curso.
  void reset() {
    _generation++;
    emit(const ProviderSearchIdle());
  }

  /// Pedido direto a [provider]. Devolve o id do pedido; falhas chegam como
  /// [ProviderSearchException] com mensagem pt-AO.
  Future<String> requestService({
    required ProviderSearchResult provider,
    required String description,
  }) async {
    if (description.trim().isEmpty) {
      throw const ProviderSearchException('Descreva o serviço de que precisa.');
    }
    return _repository.requestFromProvider(
      providerProfileId: provider.providerProfileId,
      categoryId: provider.categoryId,
      description: description,
    );
  }
}
