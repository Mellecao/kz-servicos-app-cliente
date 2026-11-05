import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/config/support_contact.dart';

void main() {
  group('supportWhatsappE164', () {
    test('is the Angolan placeholder +244 900 000 000 without the plus', () {
      expect(supportWhatsappE164, '244900000000');
    });

    test('is a valid Angolan E.164 number (244 + 9 digits)', () {
      expect(supportWhatsappE164, matches(RegExp(r'^244\d{9}$')));
    });
  });
}
