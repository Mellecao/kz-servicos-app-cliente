import 'package:kz_servicos_app/features/trip/domain/entities/trip.dart';

class TripModel {
  const TripModel({
    required this.id,
    required this.clientId,
    required this.serviceCategoryId,
    required this.pickupAddressId,
    required this.dropoffAddressId,
    required this.scheduledDatetime,
    required this.passengerCount,
    this.childrenCount = 0,
    this.luggageCount = 0,
    this.observations,
    this.paymentMethod,
    this.status = 'open',
    this.createdAt,
  });

  final String id;
  final String clientId;
  final String serviceCategoryId;
  final String pickupAddressId;
  final String dropoffAddressId;
  final DateTime scheduledDatetime;
  final int passengerCount;
  final int childrenCount;
  final int luggageCount;
  final String? observations;
  final String? paymentMethod;
  final String status;
  final DateTime? createdAt;

  static Map<String, dynamic> buildInsertJson({
    required String clientId,
    required String serviceCategoryId,
    required String pickupAddressId,
    required String dropoffAddressId,
    required DateTime scheduledDatetime,
    required int passengerCount,
    int childrenCount = 0,
    int luggageCount = 0,
    String? observations,
    String? paymentMethod,
  }) =>
      {
        'client_id': clientId,
        'service_category_id': serviceCategoryId,
        'pickup_address_id': pickupAddressId,
        'dropoff_address_id': dropoffAddressId,
        'scheduled_datetime': scheduledDatetime.toUtc().toIso8601String(),
        'passenger_count': passengerCount,
        'children_count': childrenCount,
        'luggage_count': luggageCount,
        if (observations != null) 'observations': observations,
        if (paymentMethod != null) 'payment_method': paymentMethod,
      };

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
    id: json['id'] as String,
    clientId: json['client_id'] as String,
    serviceCategoryId: json['service_category_id'] as String,
    pickupAddressId: json['pickup_address_id'] as String,
    dropoffAddressId: json['dropoff_address_id'] as String,
    scheduledDatetime: DateTime.parse(json['scheduled_datetime'] as String),
    passengerCount: json['passenger_count'] as int,
    childrenCount: (json['children_count'] as int?) ?? 0,
    luggageCount: (json['luggage_count'] as int?) ?? 0,
    observations: json['observations'] as String?,
    paymentMethod: json['payment_method'] as String?,
    status: json['status'] as String? ?? 'open',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Trip toEntity() => Trip(
    id: id,
    clientId: clientId,
    status: status,
    scheduledDatetime: scheduledDatetime,
    passengerCount: passengerCount,
    observations: observations,
    createdAt: createdAt,
  );
}
