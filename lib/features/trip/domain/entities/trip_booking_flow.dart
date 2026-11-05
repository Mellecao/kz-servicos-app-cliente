enum TripBookingMode { immediate, scheduled }

String tripTypeAfterPayment(TripBookingMode mode) =>
    mode == TripBookingMode.scheduled ? 'scheduled_choose_driver' : 'standard';

String tripTypeForQuotation() => 'scheduled_quote';

enum TripBookingStep {
  addresses,
  dateTime,
  passengers,
  luggage,
  payment,
  searchingDrivers,
}

class TripBookingFlow {
  const TripBookingFlow({required this.mode, bool isRoundTrip = false})
    : isRoundTrip = mode == TripBookingMode.scheduled && isRoundTrip;

  final TripBookingMode mode;
  final bool isRoundTrip;

  bool get allowsRoundTrip => mode == TripBookingMode.scheduled;

  List<TripBookingStep> get steps => [
    TripBookingStep.addresses,
    if (mode == TripBookingMode.scheduled) TripBookingStep.dateTime,
    TripBookingStep.passengers,
    TripBookingStep.luggage,
    TripBookingStep.payment,
    TripBookingStep.searchingDrivers,
  ];

  TripBookingFlow copyWith({TripBookingMode? mode, bool? isRoundTrip}) {
    final nextMode = mode ?? this.mode;
    return TripBookingFlow(
      mode: nextMode,
      isRoundTrip: nextMode == TripBookingMode.scheduled
          ? (isRoundTrip ?? this.isRoundTrip)
          : false,
    );
  }
}
