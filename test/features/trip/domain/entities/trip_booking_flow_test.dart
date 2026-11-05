import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_booking_flow.dart';

void main() {
  group('TripBookingFlow', () {
    test('every scheduled ride opens driver selection after payment', () {
      expect(
        tripTypeAfterPayment(TripBookingMode.scheduled),
        'scheduled_choose_driver',
      );
    });

    test('only an explicit quotation action creates an open quotation', () {
      expect(tripTypeForQuotation(), 'scheduled_quote');
    });

    test('immediate rides are always one-way', () {
      const flow = TripBookingFlow(mode: TripBookingMode.immediate);

      expect(flow.allowsRoundTrip, isFalse);
      expect(flow.steps, [
        TripBookingStep.addresses,
        TripBookingStep.passengers,
        TripBookingStep.luggage,
        TripBookingStep.payment,
        TripBookingStep.searchingDrivers,
      ]);
    });

    test('scheduled rides include date and allow round trip', () {
      const flow = TripBookingFlow(
        mode: TripBookingMode.scheduled,
        isRoundTrip: true,
      );

      expect(flow.allowsRoundTrip, isTrue);
      expect(flow.isRoundTrip, isTrue);
      expect(flow.steps, [
        TripBookingStep.addresses,
        TripBookingStep.dateTime,
        TripBookingStep.passengers,
        TripBookingStep.luggage,
        TripBookingStep.payment,
        TripBookingStep.searchingDrivers,
      ]);
    });

    test('switching to immediate clears round trip', () {
      const scheduled = TripBookingFlow(
        mode: TripBookingMode.scheduled,
        isRoundTrip: true,
      );

      final immediate = scheduled.copyWith(mode: TripBookingMode.immediate);

      expect(immediate.mode, TripBookingMode.immediate);
      expect(immediate.isRoundTrip, isFalse);
    });
  });
}
