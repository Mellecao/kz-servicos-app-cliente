class DriverVehicle {
  final String brand;
  final String model;
  final String color;
  final String licensePlate;

  const DriverVehicle({
    required this.brand,
    required this.model,
    required this.color,
    required this.licensePlate,
  });
}

class AvailableDriver {
  final String driverProfileId;
  final String fullName;
  final String? avatarUrl;
  final double? averageRating;
  final int totalRatings;
  final DriverVehicle? vehicle;

  const AvailableDriver({
    required this.driverProfileId,
    required this.fullName,
    required this.avatarUrl,
    required this.averageRating,
    required this.totalRatings,
    required this.vehicle,
  });

  factory AvailableDriver.fromMap(Map<String, dynamic> row) {
    final vehiclesRaw = (row['vehicles'] as List?) ?? const [];
    final activeVehicles = vehiclesRaw
        .whereType<Map<String, dynamic>>()
        .where((v) => v['is_active'] == true)
        .toList();
    DriverVehicle? vehicle;
    if (activeVehicles.isNotEmpty) {
      final v = activeVehicles.first;
      vehicle = DriverVehicle(
        brand: v['brand'] as String? ?? '',
        model: v['model'] as String? ?? '',
        color: v['color'] as String? ?? '',
        licensePlate: v['license_plate'] as String? ?? '',
      );
    }

    return AvailableDriver(
      driverProfileId: row['driver_profile_id'] as String,
      fullName: row['full_name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      averageRating: (row['average_rating'] as num?)?.toDouble(),
      totalRatings: (row['total_ratings'] as int?) ?? 0,
      vehicle: vehicle,
    );
  }
}
