import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/provider_search/data/models/provider_search_result.dart';

sealed class ProviderSearchState extends Equatable {
  const ProviderSearchState();

  @override
  List<Object?> get props => [];
}

/// Ainda nenhuma categoria escolhida.
class ProviderSearchIdle extends ProviderSearchState {
  const ProviderSearchIdle();
}

/// "A procurar prestadores próximos…" (radar a correr).
class ProviderSearchSearching extends ProviderSearchState {
  const ProviderSearchSearching(this.category);

  final ServiceCategory category;

  @override
  List<Object?> get props => [category.id];
}

/// Prestadores encontrados (a lista pode vir vazia).
class ProviderSearchResults extends ProviderSearchState {
  const ProviderSearchResults(this.category, this.providers);

  final ServiceCategory category;
  final List<ProviderSearchResult> providers;

  @override
  List<Object?> get props => [category.id, providers];
}

class ProviderSearchFailure extends ProviderSearchState {
  const ProviderSearchFailure(this.category, this.message);

  final ServiceCategory category;
  final String message;

  @override
  List<Object?> get props => [category.id, message];
}
