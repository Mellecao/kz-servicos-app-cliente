import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_execution_stage.dart';

void main() {
  group('TripExecutionStage.fromString', () {
    test('parses to_pickup', () {
      expect(TripExecutionStage.fromString('to_pickup'), TripExecutionStage.toPickup);
    });

    test('parses to_stop, waiting_at_stop, to_destination', () {
      expect(TripExecutionStage.fromString('to_stop'), TripExecutionStage.toStop);
      expect(TripExecutionStage.fromString('waiting_at_stop'), TripExecutionStage.waitingAtStop);
      expect(TripExecutionStage.fromString('to_destination'), TripExecutionStage.toDestination);
    });

    test('parses waiting_for_return, returning, finished', () {
      expect(TripExecutionStage.fromString('waiting_for_return'), TripExecutionStage.waitingForReturn);
      expect(TripExecutionStage.fromString('returning'), TripExecutionStage.returning);
      expect(TripExecutionStage.fromString('finished'), TripExecutionStage.finished);
    });

    test('returns null for null input', () {
      expect(TripExecutionStage.fromString(null), isNull);
    });

    test('returns null for unknown string', () {
      expect(TripExecutionStage.fromString('warp_speed'), isNull);
    });
  });

  group('TripExecutionStage.label', () {
    test('to_pickup shows Motorista a caminho', () {
      expect(TripExecutionStage.toPickup.label, 'Motorista a caminho');
    });

    test('to_stop shows A caminho da parada', () {
      expect(TripExecutionStage.toStop.label, 'A caminho da parada');
    });

    test('waiting_at_stop shows Parado na parada', () {
      expect(TripExecutionStage.waitingAtStop.label, 'Parado na parada');
    });

    test('to_destination shows A caminho do destino', () {
      expect(TripExecutionStage.toDestination.label, 'A caminho do destino');
    });

    test('waiting_for_return shows Aguardando você', () {
      expect(TripExecutionStage.waitingForReturn.label, 'Aguardando você');
    });

    test('returning shows Voltando pro ponto de partida', () {
      expect(TripExecutionStage.returning.label, 'Voltando pro ponto de partida');
    });

    test('finished shows Corrida finalizada', () {
      expect(TripExecutionStage.finished.label, 'Corrida finalizada');
    });
  });
}
