import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';

void main() {
  group('formatKz', () {
    test('formats thousands with "." and decimals with ","', () {
      expect(formatKz(1500), '1.500,00 Kz');
    });

    test('formats zero', () {
      expect(formatKz(0), '0,00 Kz');
    });

    test('formats values below one thousand without separator', () {
      expect(formatKz(999.5), '999,50 Kz');
    });

    test('groups millions', () {
      expect(formatKz(1234567.891), '1.234.567,89 Kz');
    });

    test('rounds half up to two decimals and carries into the thousands', () {
      expect(formatKz(999.999), '1.000,00 Kz');
    });

    test('keeps the minus sign for negative values', () {
      expect(formatKz(-1500), '-1.500,00 Kz');
    });

    test('accepts integers and doubles alike', () {
      expect(formatKz(11900), '11.900,00 Kz');
      expect(formatKz(11900.0), '11.900,00 Kz');
    });

    test('never contains the Brazilian currency symbol', () {
      expect(formatKz(100), isNot(contains(r'R$')));
    });
  });

  group('formatKzRange', () {
    test('drops the cents when both ends are whole numbers', () {
      expect(formatKzRange(5500, 38500), '5.500 – 38.500 Kz');
    });

    test('keeps the cents when any end has them', () {
      expect(formatKzRange(5500.5, 38500), '5.500,50 – 38.500,00 Kz');
    });

    test('shows a single value when both ends are equal', () {
      expect(formatKzRange(5500, 5500), '5.500 Kz');
    });

    test('puts the smaller value first', () {
      expect(formatKzRange(38500, 5500), '5.500 – 38.500 Kz');
    });
  });
}
