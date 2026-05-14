import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';

class AddressModel {
  const AddressModel({
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

  Map<String, dynamic> toJson() => {
    if (googlePlaceId != null) 'google_place_id': googlePlaceId,
    'formatted_address': formattedAddress,
    if (street != null) 'street': street,
    if (number != null) 'number': number,
    if (complement != null) 'complement': complement,
    if (neighborhood != null) 'neighborhood': neighborhood,
    'city': city,
    'state': state,
    if (zipCode != null) 'zip_code': zipCode,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['id'] as String?,
    googlePlaceId: json['google_place_id'] as String?,
    formattedAddress: json['formatted_address'] as String,
    street: json['street'] as String?,
    number: json['number'] as String?,
    complement: json['complement'] as String?,
    neighborhood: json['neighborhood'] as String?,
    city: json['city'] as String,
    state: json['state'] as String,
    zipCode: json['zip_code'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  factory AddressModel.fromEntity(TripAddress entity) => AddressModel(
    id: entity.id,
    googlePlaceId: entity.googlePlaceId,
    formattedAddress: entity.formattedAddress,
    street: entity.street,
    number: entity.number,
    complement: entity.complement,
    neighborhood: entity.neighborhood,
    city: entity.city,
    state: entity.state,
    zipCode: entity.zipCode,
    latitude: entity.latitude,
    longitude: entity.longitude,
  );
}
