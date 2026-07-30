class DriverCameraFollowPolicy {
  const DriverCameraFollowPolicy._();

  static const double zoom = 18;
  static const Duration minimumUpdateInterval = Duration(milliseconds: 250);

  static bool shouldUpdate({
    required DateTime? lastUpdate,
    required DateTime now,
  }) {
    return lastUpdate == null ||
        now.difference(lastUpdate) >= minimumUpdateInterval;
  }
}
