import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';

void main() {
  group('ServiceCategory', () {
    test('fromJson creates category from valid JSON', () {
      final json = {
        'id': 'uuid-123',
        'name': 'Eletricista',
        'slug': 'electrician',
        'description': 'Serviços elétricos',
        'service_type': 'other_service',
        'is_active': true,
        'icon_url': null,
      };

      final category = ServiceCategory.fromJson(json);

      expect(category.id, 'uuid-123');
      expect(category.name, 'Eletricista');
      expect(category.slug, 'electrician');
      expect(category.description, 'Serviços elétricos');
      expect(category.isActive, true);
      expect(category.icon, Icons.electrical_services);
      expect(category.color, const Color(0xFFF9A825));
    });

    test('fromJson uses fallback icon/color for unknown slug', () {
      final json = {
        'id': 'uuid-456',
        'name': 'Serviço Desconhecido',
        'slug': 'unknown_slug',
        'service_type': 'other_service',
        'is_active': true,
      };

      final category = ServiceCategory.fromJson(json);

      expect(category.icon, Icons.miscellaneous_services);
      expect(category.color, const Color(0xFF757575));
    });

    test('fromJson defaults is_active to true when null', () {
      final json = {
        'id': 'uuid-789',
        'name': 'Pintor',
        'slug': 'painter',
        'service_type': 'other_service',
      };

      final category = ServiceCategory.fromJson(json);
      expect(category.isActive, true);
    });

    test('iconForSlug returns correct icon for known slug', () {
      expect(ServiceCategory.iconForSlug('electrician'), Icons.electrical_services);
      expect(ServiceCategory.iconForSlug('plumber'), Icons.plumbing);
    });

    test('iconForSlug returns fallback for unknown slug', () {
      expect(ServiceCategory.iconForSlug('unknown'), Icons.miscellaneous_services);
    });

    test('colorForSlug returns correct color for known slug', () {
      expect(ServiceCategory.colorForSlug('electrician'), const Color(0xFFF9A825));
    });

    test('colorForSlug returns fallback for unknown slug', () {
      expect(ServiceCategory.colorForSlug('unknown'), const Color(0xFF757575));
    });
  });
}
