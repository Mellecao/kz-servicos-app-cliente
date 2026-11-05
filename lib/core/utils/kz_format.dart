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

/// Faixa de preço em Kwanzas: `5.500 – 38.500 Kz`.
///
/// Sem centavos quando os dois extremos são inteiros; com centavos nos dois
/// quando algum deles os tem. Extremos iguais mostram um só valor e o menor
/// valor vem sempre primeiro.
String formatKzRange(num min, num max) {
  final low = min <= max ? min : max;
  final high = min <= max ? max : min;
  final wholeNumbers =
      low == low.roundToDouble() && high == high.roundToDouble();
  String body(num value) {
    final formatted = formatKz(value).replaceFirst(' Kz', '');
    return wholeNumbers
        ? formatted.replaceFirst(RegExp(r',00$'), '')
        : formatted;
  }

  if (low == high) return '${body(low)} Kz';
  return '${body(low)} – ${body(high)} Kz';
}
