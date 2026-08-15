import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/services/active_scheduled_direct_gate.dart';

void main() {
  group('ActiveScheduledDirectGate.resolvePathForTrip', () {
    test('retoma proposta pendente após reabrir o app', () {
      expect(
        ActiveScheduledDirectGate.resolvePathForTrip(
          tripId: 'trip-1',
          status: 'awaiting_client_confirmation',
        ),
        '/scheduled-choose-driver/price-review/trip-1',
      );
    });

    test('retoma espera pela resposta do motorista', () {
      expect(
        ActiveScheduledDirectGate.resolvePathForTrip(
          tripId: 'trip-2',
          status: 'awaiting_driver_confirmation',
        ),
        '/scheduled-choose-driver/awaiting/trip-2',
      );
    });

    test('não intercepta corrida sem ação pendente', () {
      expect(
        ActiveScheduledDirectGate.resolvePathForTrip(
          tripId: 'trip-3',
          status: 'scheduled',
        ),
        isNull,
      );
    });
  });
}
