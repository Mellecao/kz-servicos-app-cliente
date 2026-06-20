abstract final class GoogleMapsApiKey {
  static const value = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCwDyzjfdpfbRU06n6GwzlqbIj_-xfgLHw',
  );
}
