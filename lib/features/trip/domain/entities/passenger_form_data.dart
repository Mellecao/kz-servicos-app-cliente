class PassengerFormData {
  const PassengerFormData({
    required this.adults,
    required this.scheduledDatetime,
    this.hasChildren = false,
    this.childrenDescription,
    this.hasLuggage = false,
    this.luggageDescription,
    this.observations,
  });

  final int adults;
  final DateTime scheduledDatetime;
  final bool hasChildren;
  final String? childrenDescription;
  final bool hasLuggage;
  final String? luggageDescription;
  final String? observations;
}
