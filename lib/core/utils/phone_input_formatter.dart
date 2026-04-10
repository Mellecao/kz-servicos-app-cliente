import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 11) {
      return oldValue;
    }

    final formatted = _format(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length <= 2) return '($digits';
    if (digits.length <= 3) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    }

    final ddd = digits.substring(0, 2);
    final rest = digits.substring(2);

    if (digits.length <= 6) {
      return '($ddd) $rest';
    }

    if (digits.length <= 10) {
      // (XX) XXXX-XXXX
      return '($ddd) ${rest.substring(0, rest.length - 4)}'
          '-${rest.substring(rest.length - 4)}';
    }

    // 11 digits: (XX) X.XXXX-XXXX
    return '($ddd) ${rest.substring(0, 1)}'
        '.${rest.substring(1, 5)}'
        '-${rest.substring(5)}';
  }
}
