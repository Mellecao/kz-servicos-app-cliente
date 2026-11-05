import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/utils/angola_phone.dart';

TextEditingValue _edit(
  AngolaPhoneInputFormatter formatter,
  String oldText,
  String newText,
) {
  return formatter.formatEditUpdate(
    TextEditingValue(text: oldText),
    TextEditingValue(text: newText),
  );
}

void main() {
  group('angolaPhoneDigits', () {
    test('removes spaces and keeps the 9 national digits', () {
      expect(angolaPhoneDigits('912 345 678'), '912345678');
    });

    test('strips the +244 prefix', () {
      expect(angolaPhoneDigits('+244 912 345 678'), '912345678');
      expect(angolaPhoneDigits('+244912345678'), '912345678');
    });

    test('strips a bare 244 prefix only when the number is complete', () {
      expect(angolaPhoneDigits('244912345678'), '912345678');
      // 9 dígitos começados por 244 são um número nacional, não o prefixo.
      expect(angolaPhoneDigits('244123456'), '244123456');
    });

    test('truncates anything beyond 9 digits', () {
      expect(angolaPhoneDigits('9123456789'), '912345678');
    });

    test('returns empty for empty or non-numeric input', () {
      expect(angolaPhoneDigits(''), '');
      expect(angolaPhoneDigits('abc'), '');
    });
  });

  group('formatAngolaPhone', () {
    test('groups progressively as 3-3-3', () {
      expect(formatAngolaPhone('9'), '9');
      expect(formatAngolaPhone('912'), '912');
      expect(formatAngolaPhone('9123'), '912 3');
      expect(formatAngolaPhone('912345'), '912 345');
      expect(formatAngolaPhone('9123456'), '912 345 6');
      expect(formatAngolaPhone('912345678'), '912 345 678');
    });
  });

  group('isValidAngolaPhone', () {
    test('accepts mobile numbers (9 digits starting with 9)', () {
      expect(isValidAngolaPhone('912345678'), isTrue);
      expect(isValidAngolaPhone('923 000 001'), isTrue);
      expect(isValidAngolaPhone('+244 923 000 001'), isTrue);
    });

    test('accepts Luanda landlines (9 digits starting with 2)', () {
      expect(isValidAngolaPhone('222123456'), isTrue);
    });

    test('rejects short numbers and other prefixes', () {
      expect(isValidAngolaPhone(''), isFalse);
      expect(isValidAngolaPhone('91234567'), isFalse);
      expect(isValidAngolaPhone('812345678'), isFalse);
      expect(isValidAngolaPhone('112345678'), isFalse);
    });
  });

  group('toE164Angola', () {
    test('stores as +244 followed by 9 digits, without spaces', () {
      expect(toE164Angola('912 345 678'), '+244912345678');
      expect(toE164Angola('+244 923000001'), '+244923000001');
    });

    test('returns empty for empty input', () {
      expect(toE164Angola(''), '');
      expect(toE164Angola('   '), '');
    });
  });

  group('displayAngolaPhone', () {
    test('shows +244 9XX XXX XXX for stored E.164 numbers', () {
      expect(displayAngolaPhone('+244923000001'), '+244 923 000 001');
    });

    test('leaves legacy or foreign numbers untouched', () {
      expect(displayAngolaPhone('+5511999999999'), '+5511999999999');
      expect(displayAngolaPhone('(11) 9.9999-9999'), '(11) 9.9999-9999');
    });

    test('handles null and empty', () {
      expect(displayAngolaPhone(null), '');
      expect(displayAngolaPhone(''), '');
    });
  });

  group('editableAngolaPhone', () {
    test('gives the national 9XX XXX XXX for stored +244 numbers', () {
      expect(editableAngolaPhone('+244923000001'), '923 000 001');
    });

    test('is empty for legacy, foreign, null or empty values', () {
      expect(editableAngolaPhone('+5511999999999'), '');
      expect(editableAngolaPhone('(11) 9.9999-9999'), '');
      expect(editableAngolaPhone(null), '');
      expect(editableAngolaPhone(''), '');
    });
  });

  group('AngolaPhoneInputFormatter', () {
    final formatter = AngolaPhoneInputFormatter();

    test('formats while typing', () {
      expect(_edit(formatter, '912 34', '912 345').text, '912 345');
      expect(_edit(formatter, '', '9').text, '9');
    });

    test('formats a pasted international number without duplicating the DDI',
        () {
      expect(_edit(formatter, '', '+244912345678').text, '912 345 678');
    });

    test('ignores digits beyond the 9th', () {
      expect(_edit(formatter, '912 345 678', '912 345 6789').text,
          '912 345 678');
    });

    test('keeps the cursor at the end', () {
      final value = _edit(formatter, '', '912345');
      expect(value.selection.baseOffset, value.text.length);
    });
  });
}
