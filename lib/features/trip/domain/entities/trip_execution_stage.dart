/// Mirror of Postgres enum `public.trip_execution_stage`.
/// Values reflect the current stage of a trip in execution.
enum TripExecutionStage {
  toPickup('to_pickup', 'Motorista a caminho'),
  toStop('to_stop', 'A caminho da parada'),
  waitingAtStop('waiting_at_stop', 'Parado na parada'),
  toDestination('to_destination', 'A caminho do destino'),
  waitingForReturn('waiting_for_return', 'A aguardar por si'),
  returning('returning', 'Voltando pro ponto de partida'),
  finished('finished', 'Viagem concluída');

  const TripExecutionStage(this.wireValue, this.label);

  /// Value as stored in Postgres (snake_case).
  final String wireValue;

  /// User-facing label (pt-BR) for badges/UI.
  final String label;

  /// Parses a Postgres value into the enum. Returns `null` for `null` or
  /// unknown strings (forward-compat).
  static TripExecutionStage? fromString(String? value) {
    if (value == null) return null;
    for (final s in TripExecutionStage.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}
