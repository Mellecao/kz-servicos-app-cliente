import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';

/// Uma linha de `rpc('search_service_providers')`: um prestador perto do cliente
/// (preços em Kz, tempo em minutos, posição simulada pelo servidor).
class ProviderSearchResult extends Equatable {
  const ProviderSearchResult({
    required this.providerProfileId,
    required this.fullName,
    required this.categoryId,
    required this.categoryName,
    required this.priceMin,
    required this.priceMax,
    required this.avgResponseMinutes,
    required this.lat,
    required this.lng,
    this.avatarUrl,
    this.bio,
    this.averageRating,
    this.totalRatings = 0,
    this.isDemo = false,
    this.distanceM = 0,
  });

  factory ProviderSearchResult.fromJson(Map<String, dynamic> json) {
    return ProviderSearchResult(
      providerProfileId: json['provider_profile_id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      categoryId: json['category_id'] as String,
      categoryName: (json['category_name'] as String?) ?? '',
      averageRating: _toDoubleOrNull(json['average_rating']),
      totalRatings: _toDoubleOrNull(json['total_ratings'])?.round() ?? 0,
      priceMin: _toDoubleOrNull(json['price_min']) ?? 0,
      priceMax: _toDoubleOrNull(json['price_max']) ?? 0,
      avgResponseMinutes:
          _toDoubleOrNull(json['avg_response_minutes'])?.round() ?? 0,
      isDemo: json['is_demo'] as bool? ?? false,
      lat: _toDoubleOrNull(json['lat']) ?? 0,
      lng: _toDoubleOrNull(json['lng']) ?? 0,
      distanceM: _toDoubleOrNull(json['distance_m']) ?? 0,
    );
  }

  final String providerProfileId;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String categoryId;
  final String categoryName;
  final double? averageRating;
  final int totalRatings;
  final double priceMin;
  final double priceMax;
  final int avgResponseMinutes;
  final bool isDemo;
  final double lat;
  final double lng;
  final double distanceM;

  /// Primeira letra do primeiro e do último nome (`Miguel Prestador` → `MP`).
  String get initials {
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first[0].toUpperCase();
    if (words.length == 1) return first;
    return '$first${words.last[0].toUpperCase()}';
  }

  String get priceRangeLabel => formatKzRange(priceMin, priceMax);

  String get responseLabel => avgResponseMinutes >= 60
      ? 'Responde em ~${(avgResponseMinutes / 60).round()} h'
      : 'Responde em ~$avgResponseMinutes min';

  bool get hasReviews => averageRating != null && totalRatings > 0;

  String get ratingLabel => hasReviews
      ? averageRating!.toStringAsFixed(1).replaceFirst('.', ',')
      : 'Novo';

  String get reviewsLabel {
    if (!hasReviews) return 'Sem avaliações';
    return totalRatings == 1 ? '1 avaliação' : '$totalRatings avaliações';
  }

  @override
  List<Object?> get props => [
    providerProfileId,
    fullName,
    avatarUrl,
    bio,
    categoryId,
    categoryName,
    averageRating,
    totalRatings,
    priceMin,
    priceMax,
    avgResponseMinutes,
    isDemo,
    lat,
    lng,
    distanceM,
  ];
}

double? _toDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
