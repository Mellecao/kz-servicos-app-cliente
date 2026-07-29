import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripStop extends Equatable {
  const TripStop({
    required this.id,
    required this.stopOrder,
    required this.location,
    required this.address,
  });

  final String id;
  final int stopOrder;
  final LatLng location;
  final String address;

  @override
  List<Object?> get props => [id, stopOrder];
}
