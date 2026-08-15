import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes.dart';

void main() {
  test('corrida confirmada usa a rota ativa existente no app', () {
    expect(
      ScheduledDirectRoutes.activeTrip('trip-123'),
      '/trip?activeTripId=trip-123',
    );
  });
}
