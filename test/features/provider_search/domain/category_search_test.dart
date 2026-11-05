import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/provider_search/domain/category_search.dart';

ServiceCategory _category(String name, {String? description}) =>
    ServiceCategory(
      id: name,
      name: name,
      slug: name.toLowerCase(),
      description: description,
      icon: Icons.build,
      color: Colors.orange,
    );

void main() {
  final canalizador = _category(
    'Canalizador',
    description: 'Fugas, torneiras e canalizações',
  );
  final eletricista = _category(
    'Eletricista',
    description: 'Reparações elétricas e instalações',
  );
  final domestica = _category(
    'Empregada doméstica',
    description: 'Limpeza e arrumação da casa',
  );
  final limpeza = _category('Limpeza geral');
  final all = [canalizador, eletricista, domestica, limpeza];

  group('normalizeSearchText', () {
    test('removes accents, lowercases and trims', () {
      expect(normalizeSearchText('  DOMÉSTICA  '), 'domestica');
      expect(normalizeSearchText('Canalização'), 'canalizacao');
      expect(normalizeSearchText('Ação ñ ü'), 'acao n u');
    });

    test('collapses inner whitespace', () {
      expect(normalizeSearchText('ar   condicionado'), 'ar condicionado');
    });
  });

  group('filterCategories', () {
    test('finds by name ignoring case', () {
      expect(filterCategories(all, 'canal'), [canalizador]);
      expect(filterCategories(all, 'CANALIZADOR'), [canalizador]);
    });

    test('finds ignoring accents on either side', () {
      expect(filterCategories(all, 'domestica'), [domestica]);
      expect(filterCategories(all, 'doméstica'), [domestica]);
      expect(filterCategories(all, 'eletrica'), [eletricista]);
    });

    test('also matches the description', () {
      expect(filterCategories(all, 'torneira'), [canalizador]);
    });

    test('returns an empty list for an empty or blank query', () {
      expect(filterCategories(all, ''), isEmpty);
      expect(filterCategories(all, '   '), isEmpty);
    });

    test('returns an empty list when nothing matches', () {
      expect(filterCategories(all, 'astronauta'), isEmpty);
    });

    test('ranks name matches before description matches', () {
      // "limpeza" está no nome de "Limpeza geral" e só na descrição da doméstica.
      expect(filterCategories(all, 'limpeza'), [limpeza, domestica]);
    });

    test('ranks names that start with the query first', () {
      final result = filterCategories(all, 'e');
      expect(result.first, anyOf(eletricista, domestica));
      expect(result.indexOf(canalizador), greaterThan(0));
    });
  });
}
