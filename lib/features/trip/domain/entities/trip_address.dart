import 'package:equatable/equatable.dart';

class TripAddress extends Equatable {
  const TripAddress({
    this.id,
    this.googlePlaceId,
    required this.formattedAddress,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    required this.city,
    required this.state,
    this.zipCode,
    required this.latitude,
    required this.longitude,
  });

  final String? id;
  final String? googlePlaceId;
  final String formattedAddress;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String city;
  final String state;
  final String? zipCode;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [
    id,
    googlePlaceId,
    formattedAddress,
    latitude,
    longitude,
  ];
}
