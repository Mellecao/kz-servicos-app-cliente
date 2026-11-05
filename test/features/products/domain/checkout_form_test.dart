import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/products/domain/checkout_form.dart';

void main() {
  group('validateDeliveryAddress', () {
    test('exige morada', () {
      expect(validateDeliveryAddress(''), isNotNull);
      expect(validateDeliveryAddress('   '), isNotNull);
      expect(validateDeliveryAddress(null), isNotNull);
      expect(validateDeliveryAddress('Talatona, Luanda'), isNull);
    });
  });

  group('validateContactPhone', () {
    test('exige telemóvel angolano válido', () {
      expect(validateContactPhone(''), isNotNull);
      expect(validateContactPhone('123'), isNotNull);
      expect(validateContactPhone('812 345 678'), isNotNull);
      expect(validateContactPhone('923 000 001'), isNull);
      expect(validateContactPhone('+244 923 000 001'), isNull);
      expect(validateContactPhone('222 123 456'), isNull);
    });
  });

  group('CheckoutForm', () {
    test('grava o telemóvel em E.164 sem espaços e limpa campos vazios', () {
      final form = CheckoutForm(
        address: '  Talatona, Luanda ',
        reference: '  ',
        phone: '923 000 001',
        paymentMethod: 'debit',
        notes: ' Portão azul ',
      );
      expect(form.isValid, isTrue);
      expect(form.phoneE164, '+244923000001');
      expect(form.cleanAddress, 'Talatona, Luanda');
      expect(form.cleanReference, isNull);
      expect(form.cleanNotes, 'Portão azul');
    });

    test('inválido sem morada ou com telemóvel mau', () {
      expect(
        CheckoutForm(
          address: '',
          phone: '923000001',
          paymentMethod: 'cash',
        ).isValid,
        isFalse,
      );
      expect(
        CheckoutForm(
          address: 'Viana',
          phone: '12',
          paymentMethod: 'cash',
        ).isValid,
        isFalse,
      );
    });

    test('rejeita método de pagamento fora de cash|debit|credit', () {
      expect(
        CheckoutForm(
          address: 'Viana',
          phone: '923000001',
          paymentMethod: 'pix',
        ).isValid,
        isFalse,
      );
    });
  });
}
