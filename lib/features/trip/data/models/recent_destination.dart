class RecentDestination {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? savedLabel;

  const RecentDestination({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.savedLabel,
  });

  bool get isHome => savedLabel == 'home';
  bool get isWork => savedLabel == 'work';
}
