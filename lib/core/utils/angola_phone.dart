import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Telefones de Angola. Mostra-se `+244 9XX XXX XXX`; grava-se em E.164 sem
/// espaços (`+244923000001`). Comparações e pesquisas fazem-se só por dígitos.
/// Móvel: 9 dígitos começados por 9. Fixo de Luanda: 9 dígitos começados por 2.

const String _angolaDdi = '244';
const int _nationalLength = 9;

/// Dígitos nacionais (no máximo 9), sem formatação nem prefixo `+244`.
///
/// O prefixo só é removido quando é inequívoco: com `+` explícito ou com
/// `244` seguido de um número completo (12 dígitos). Assim `244123456` (9
/// dígitos) continua a ser um número nacional.
String angolaPhoneDigits(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  final hasPlus = input.trimLeft().startsWith('+');
  if (digits.startsWith(_angolaDdi) && (hasPlus || digits.length >= 12)) {
    digits = digits.substring(_angolaDdi.length);
  }
  return digits.length > _nationalLength
      ? digits.substring(0, _nationalLength)
      : digits;
}

/// Agrupa os dígitos nacionais em blocos de 3: `912 345 678`.
String formatAngolaPhone(String input) {
  final digits = angolaPhoneDigits(input);
  final groups = <String>[];
  for (var i = 0; i < digits.length; i += 3) {
    groups.add(digits.substring(i, math.min(i + 3, digits.length)));
  }
  return groups.join(' ');
}

bool isValidAngolaPhone(String input) {
  final digits = angolaPhoneDigits(input);
  return digits.length == _nationalLength &&
      (digits.startsWith('9') || digits.startsWith('2'));
}

/// Valor a gravar: `+244` + 9 dígitos, sem espaços. Vazio se não houver dígitos.
/// Validar com [isValidAngolaPhone] antes de gravar.
String toE164Angola(String input) {
  final digits = angolaPhoneDigits(input);
  return digits.isEmpty ? '' : '+$_angolaDdi$digits';
}

/// Valor a mostrar: `+244 9XX XXX XXX` para números E.164 angolanos. Dados
/// legados ou estrangeiros (por exemplo `+55…`) ficam exatamente como estão.
String displayAngolaPhone(String? stored) {
  if (stored == null || stored.isEmpty) return '';
  final match = RegExp(r'^\+244(\d{9})$').firstMatch(stored);
  if (match == null) return stored;
  return '+$_angolaDdi ${formatAngolaPhone(match.group(1)!)}';
}

/// Valor inicial para editar: `9XX XXX XXX` se o número gravado for `+244…`.
/// Vazio para dados legados/estrangeiros: ficam intactos até o utilizador
/// gravar um número angolano novo.
String editableAngolaPhone(String? stored) {
  if (stored == null) return '';
  final match = RegExp(r'^\+244(\d{9})$').firstMatch(stored);
  return match == null ? '' : formatAngolaPhone(match.group(1)!);
}

/// Máscara do campo de telefone (sem o `+244`, mostrado como prefixo do campo).
class AngolaPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatAngolaPhone(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
