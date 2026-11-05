import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/provider_search/data/models/provider_search_result.dart';

Map<String, dynamic> _json({
  Object? name = 'Miguel Prestador',
  Object? avatar,
  Object? rating = 4.8,
  Object? total = 23,
  Object? min = 5500,
  Object? max = 38500,
  Object? minutes = 18,
}) => {
  'provider_profile_id': 'p-1',
  'full_name': name,
  'avatar_url': avatar,
  'bio': 'Canalizador com 10 anos de experiência.',
  'category_id': 'c-1',
  'category_name': 'Canalizador',
  'average_rating': rating,
  'total_ratings': total,
  'price_min': min,
  'price_max': max,
  'avg_response_minutes': minutes,
  'is_demo': false,
  'lat': -8.84,
  'lng': 13.23,
  'distance_m': 420.7,
};

void main() {
  group('ProviderSearchResult.fromJson', () {
    test('maps every field of the RPC row', () {
      final p = ProviderSearchResult.fromJson(_json());
      expect(p.providerProfileId, 'p-1');
      expect(p.fullName, 'Miguel Prestador');
      expect(p.avatarUrl, isNull);
      expect(p.bio, startsWith('Canalizador'));
      expect(p.categoryId, 'c-1');
      expect(p.categoryName, 'Canalizador');
      expect(p.averageRating, 4.8);
      expect(p.totalRatings, 23);
      expect(p.priceMin, 5500);
      expect(p.priceMax, 38500);
      expect(p.avgResponseMinutes, 18);
      expect(p.isDemo, isFalse);
      expect(p.lat, -8.84);
      expect(p.lng, 13.23);
      expect(p.distanceM, 420.7);
    });

    test('accepts numbers sent as strings (numeric columns)', () {
      final p = ProviderSearchResult.fromJson(
        _json(rating: '4.50', min: '5500.00', max: '38500.00', minutes: '18'),
      );
      expect(p.averageRating, 4.5);
      expect(p.priceMin, 5500);
      expect(p.priceMax, 38500);
      expect(p.avgResponseMinutes, 18);
    });

    test('keeps a missing rating as null', () {
      final p = ProviderSearchResult.fromJson(_json(rating: null, total: 0));
      expect(p.averageRating, isNull);
      expect(p.totalRatings, 0);
    });
  });

  group('labels', () {
    test('initials use first and last word', () {
      expect(ProviderSearchResult.fromJson(_json()).initials, 'MP');
      expect(
        ProviderSearchResult.fromJson(
          _json(name: 'ana maria da silva'),
        ).initials,
        'AS',
      );
      expect(ProviderSearchResult.fromJson(_json(name: 'João')).initials, 'J');
      expect(ProviderSearchResult.fromJson(_json(name: '  ')).initials, '?');
    });

    test('price range uses Kz without cents when both are whole', () {
      expect(
        ProviderSearchResult.fromJson(_json()).priceRangeLabel,
        '5.500 – 38.500 Kz',
      );
    });

    test('response label is in minutes, and in hours from 60 min', () {
      expect(
        ProviderSearchResult.fromJson(_json()).responseLabel,
        'Responde em ~18 min',
      );
      expect(
        ProviderSearchResult.fromJson(_json(minutes: 120)).responseLabel,
        'Responde em ~2 h',
      );
    });

    test('rating label uses a decimal comma and reviews are pluralised', () {
      final p = ProviderSearchResult.fromJson(_json());
      expect(p.ratingLabel, '4,8');
      expect(p.reviewsLabel, '23 avaliações');
      expect(
        ProviderSearchResult.fromJson(_json(total: 1)).reviewsLabel,
        '1 avaliação',
      );
    });

    test('a provider without reviews is "Novo"', () {
      final p = ProviderSearchResult.fromJson(_json(rating: null, total: 0));
      expect(p.ratingLabel, 'Novo');
      expect(p.reviewsLabel, 'Sem avaliações');
    });
  });
}
