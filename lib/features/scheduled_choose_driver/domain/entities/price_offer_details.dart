class PriceOfferVehicle {
  const PriceOfferVehicle({
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.passengerCapacity,
    required this.photoUrls,
  });

  final String brand;
  final String model;
  final int? year;
  final String color;
  final String licensePlate;
  final int passengerCapacity;
  final List<String> photoUrls;
}

class PriceOfferDetails {
  const PriceOfferDetails({
    required this.driverName,
    required this.driverAvatarUrl,
    required this.rating,
    required this.totalRatings,
    required this.completedTrips,
    required this.driverPhotoUrls,
    required this.vehicle,
    required this.pickupAddress,
    required this.stopAddresses,
    required this.dropoffAddress,
    required this.scheduledDatetime,
    required this.passengerCount,
    required this.childrenCount,
    required this.luggageCount,
    required this.observations,
  });

  final String driverName;
  final String? driverAvatarUrl;
  final double? rating;
  final int totalRatings;
  final int completedTrips;
  final List<String> driverPhotoUrls;
  final PriceOfferVehicle? vehicle;
  final String pickupAddress;
  final List<String> stopAddresses;
  final String dropoffAddress;
  final DateTime? scheduledDatetime;
  final int passengerCount;
  final int childrenCount;
  final int luggageCount;
  final String? observations;

  factory PriceOfferDetails.fromMap(Map<String, dynamic> row) {
    final driver = row['driver_profiles'] as Map<String, dynamic>?;
    final provider = driver?['provider_profiles'] as Map<String, dynamic>?;
    final user = provider?['users'] as Map<String, dynamic>?;
    final vehicles =
        (driver?['vehicles'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];
    Map<String, dynamic>? vehicleMap;
    for (final item in vehicles) {
      if (item['id'] == row['vehicle_id']) {
        vehicleMap = item;
        break;
      }
    }
    vehicleMap ??= vehicles
        .where((item) => item['is_active'] == true)
        .firstOrNull;
    vehicleMap ??= vehicles.firstOrNull;

    final vehiclePhotos =
        (vehicleMap?['vehicle_photos'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((photo) => photo['photo_url'] as String?)
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        const <String>[];
    final driverPhotos =
        (driver?['driver_profile_photos'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((photo) => photo['photo_url'] as String?)
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        const <String>[];
    final stops =
        (row['trip_stops'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];
    stops.sort(
      (a, b) => ((a['stop_order'] as num?)?.toInt() ?? 0).compareTo(
        (b['stop_order'] as num?)?.toInt() ?? 0,
      ),
    );

    return PriceOfferDetails(
      driverName: user?['full_name'] as String? ?? 'Motorista parceiro',
      driverAvatarUrl: user?['avatar_url'] as String?,
      rating: (provider?['average_rating'] as num?)?.toDouble(),
      totalRatings: (provider?['total_ratings'] as num?)?.toInt() ?? 0,
      completedTrips: (row['completed_trips'] as num?)?.toInt() ?? 0,
      driverPhotoUrls: driverPhotos,
      vehicle: vehicleMap == null
          ? null
          : PriceOfferVehicle(
              brand: vehicleMap['brand'] as String? ?? '',
              model: vehicleMap['model'] as String? ?? '',
              year: (vehicleMap['year'] as num?)?.toInt(),
              color: vehicleMap['color'] as String? ?? '',
              licensePlate: vehicleMap['license_plate'] as String? ?? '',
              passengerCapacity:
                  (vehicleMap['passenger_capacity'] as num?)?.toInt() ?? 4,
              photoUrls: vehiclePhotos,
            ),
      pickupAddress: _address(row['pickup_address']),
      stopAddresses: stops
          .map((stop) => _address(stop['addresses']))
          .toList(growable: false),
      dropoffAddress: _address(row['dropoff_address']),
      scheduledDatetime: DateTime.tryParse(
        row['scheduled_datetime'] as String? ?? '',
      )?.toLocal(),
      passengerCount: (row['passenger_count'] as num?)?.toInt() ?? 1,
      childrenCount: (row['children_count'] as num?)?.toInt() ?? 0,
      luggageCount: (row['luggage_count'] as num?)?.toInt() ?? 0,
      observations: row['observations'] as String?,
    );
  }

  static String _address(dynamic raw) {
    final value = raw is Map<String, dynamic> ? raw['formatted_address'] : null;
    return value is String && value.isNotEmpty
        ? value
        : 'Endereço não informado';
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
