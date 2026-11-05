import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';

const Map<String, String> _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

/// Minúsculas, sem acentos e com espaços normalizados: base da pesquisa de
/// categorias ("DOMÉSTICA" encontra "Empregada doméstica").
String normalizeSearchText(String value) {
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Categorias cujo nome ou descrição contêm [query] (sem acentos nem
/// maiúsculas). Consulta vazia devolve lista vazia. Ordem: nome que começa pela
/// consulta, nome que a contém, e por fim só a descrição; em caso de empate
/// mantém a ordem recebida.
List<ServiceCategory> filterCategories(
  List<ServiceCategory> categories,
  String query,
) {
  final needle = normalizeSearchText(query);
  if (needle.isEmpty) return const [];

  final ranked = <({ServiceCategory category, int rank, int index})>[];
  for (var i = 0; i < categories.length; i++) {
    final category = categories[i];
    final name = normalizeSearchText(category.name);
    final description = normalizeSearchText(category.description ?? '');
    final int? rank;
    if (name.startsWith(needle) ||
        name.split(' ').any((w) => w.startsWith(needle))) {
      rank = 0;
    } else if (name.contains(needle)) {
      rank = 1;
    } else if (description.contains(needle)) {
      rank = 2;
    } else {
      rank = null;
    }
    if (rank != null) ranked.add((category: category, rank: rank, index: i));
  }
  ranked.sort((a, b) {
    final byRank = a.rank.compareTo(b.rank);
    return byRank != 0 ? byRank : a.index.compareTo(b.index);
  });
  return [for (final r in ranked) r.category];
}
