import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

class PassengerFormData {
  const PassengerFormData({
    required this.adults,
    required this.scheduledDatetime,
    this.hasChildren = false,
    this.childrenDescription,
    this.hasLuggage = false,
    this.luggageDescription,
    this.observations,
    this.paymentMethod = 'cash',
    this.isRoundTrip = false,
    this.returnDatetime,
    this.passengers = const [],
    this.luggage = const [],
  });

  PassengerFormData copyWith({
    int? adults,
    DateTime? scheduledDatetime,
    bool? hasChildren,
    String? childrenDescription,
    bool? hasLuggage,
    String? luggageDescription,
    String? observations,
    String? paymentMethod,
    bool? isRoundTrip,
    DateTime? returnDatetime,
    List<TripPassengerData>? passengers,
    List<TripLuggageData>? luggage,
  }) {
    return PassengerFormData(
      adults: adults ?? this.adults,
      scheduledDatetime: scheduledDatetime ?? this.scheduledDatetime,
      hasChildren: hasChildren ?? this.hasChildren,
      childrenDescription: childrenDescription ?? this.childrenDescription,
      hasLuggage: hasLuggage ?? this.hasLuggage,
      luggageDescription: luggageDescription ?? this.luggageDescription,
      observations: observations ?? this.observations,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      returnDatetime: returnDatetime ?? this.returnDatetime,
      passengers: passengers ?? this.passengers,
      luggage: luggage ?? this.luggage,
    );
  }

  final int adults;
  final DateTime scheduledDatetime;
  final bool hasChildren;
  final String? childrenDescription;
  final bool hasLuggage;
  final String? luggageDescription;
  final String? observations;
  final String paymentMethod;
  final bool isRoundTrip;
  final DateTime? returnDatetime;
  final List<TripPassengerData> passengers;
  final List<TripLuggageData> luggage;
}
