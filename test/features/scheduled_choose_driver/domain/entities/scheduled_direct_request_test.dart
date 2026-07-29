import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart';

void main() {
  group('scheduledDirectStatusFrom', () {
    test('trip awaiting_driver_confirmation + candidate pending → awaitingDriver', () {
      expect(
        scheduledDirectStatusFrom(
          tripStatus: 'awaiting_driver_confirmation',
          candidateStatus: 'pending',
        ),
        ScheduledDirectStatus.awaitingDriver,
      );
    });

    test('trip awaiting_client_confirmation + candidate accepted → priceOffered', () {
      expect(
        scheduledDirectStatusFrom(
          tripStatus: 'awaiting_client_confirmation',
          candidateStatus: 'accepted',
        ),
        ScheduledDirectStatus.priceOffered,
      );
    });

    test('trip searching_drivers + candidate rejected → rejected', () {
      expect(
        scheduledDirectStatusFrom(
          tripStatus: 'searching_drivers',
          candidateStatus: 'rejected',
        ),
        ScheduledDirectStatus.rejected,
      );
    });

    test('trip scheduled → confirmed', () {
      expect(
        scheduledDirectStatusFrom(
          tripStatus: 'scheduled',
          candidateStatus: 'accepted',
        ),
        ScheduledDirectStatus.confirmed,
      );
    });

    test('trip cancelled → cancelled', () {
      expect(
        scheduledDirectStatusFrom(
          tripStatus: 'cancelled',
          candidateStatus: 'rejected',
        ),
        ScheduledDirectStatus.cancelled,
      );
    });

    test('valor desconhecido → awaitingDriver (defesa)', () {
      expect(
        scheduledDirectStatusFrom(
          tripStatus: 'unknown',
          candidateStatus: 'unknown',
        ),
        ScheduledDirectStatus.awaitingDriver,
      );
    });
  });
}
