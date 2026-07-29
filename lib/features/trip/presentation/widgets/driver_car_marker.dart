/// Maps a compass bearing (0..360 degrees) to one of 12 pre-rendered car
/// sprites at 30° increments. North=0 → car_00.png; East=90 → car_03.png;
/// South=180 → car_06.png; West=270 → car_09.png.
class DriverCarMarker {
  static const int _bucketCount = 12;
  static const double _stepDegrees = 360.0 / _bucketCount; // 30°
  static const String _basePath = 'public/assets/sprite/car';

  const DriverCarMarker._();

  /// Returns the asset path for the nearest sprite to [bearingDegrees].
  /// Handles negative and >360 bearings by normalizing modulo 360.
  static String assetForBearing(double bearingDegrees) {
    final normalized = _normalize(bearingDegrees);
    final index = (normalized / _stepDegrees).round() % _bucketCount;
    final padded = index.toString().padLeft(2, '0');
    return '$_basePath/car_$padded.png';
  }

  static double _normalize(double degrees) {
    var d = degrees % 360;
    if (d < 0) d += 360;
    return d;
  }
}
