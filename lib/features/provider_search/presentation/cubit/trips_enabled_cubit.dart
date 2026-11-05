import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/trips_enabled_repository.dart';

/// `loading` até a primeira leitura; depois `enabled` ou `disabled`.
enum TripsEnabledState { loading, enabled, disabled }

/// Interruptor único `system_settings.trips_enabled`: escolhe a home do Cliente.
class TripsEnabledCubit extends Cubit<TripsEnabledState> {
  TripsEnabledCubit({required TripsEnabledRepository repository})
    : _repository = repository,
      super(TripsEnabledState.loading);

  final TripsEnabledRepository _repository;

  /// Lê o interruptor. Mantém o valor atual enquanto relê (sem piscar a tela);
  /// falha ⇒ `disabled`.
  Future<void> load() async {
    bool enabled;
    try {
      enabled = await _repository.fetchTripsEnabled();
    } catch (_) {
      enabled = false;
    }
    if (isClosed) return;
    emit(enabled ? TripsEnabledState.enabled : TripsEnabledState.disabled);
  }
}
