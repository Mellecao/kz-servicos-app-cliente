abstract final class ScheduledDirectRoutes {
  static String activeTrip(String tripId) =>
      Uri(path: '/trip', queryParameters: {'activeTripId': tripId}).toString();
}
