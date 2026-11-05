/// Formata um valor em Kwanzas: `1.500,00 Kz` (milhar `.`, decimal `,`).
///
/// Único formatter de moeda da app. Separadores explícitos: o `pt_PT` do
/// `intl` agrupa com espaço, o que não é o formato pedido para Angola.
String formatKz(num value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final isNegative = value < 0 && fixed != '0.00';
  return '${isNegative ? '-' : ''}$integer,${parts[1]} Kz';
}
