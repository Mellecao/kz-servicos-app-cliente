import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/quotation_availability.dart';

DateTime at(int hour) => DateTime(2026, 7, 29, hour, 0, 0);

void main() {
  group('computeQuotationAvailability', () {
    test("override='auto' e hora=14 → available", () {
      expect(
        computeQuotationAvailability(nowInSp: at(14), adminOverride: 'auto'),
        QuotationAvailability.available,
      );
    });

    test("override='auto' e hora=6 → unavailable", () {
      expect(
        computeQuotationAvailability(nowInSp: at(6), adminOverride: 'auto'),
        QuotationAvailability.unavailable,
      );
    });

    test("override='auto' borda inferior: 07:00 → available, 06:59 → unavailable", () {
      expect(
        computeQuotationAvailability(nowInSp: at(7), adminOverride: 'auto'),
        QuotationAvailability.available,
      );
      expect(
        computeQuotationAvailability(nowInSp: DateTime(2026, 7, 29, 6, 59, 0), adminOverride: 'auto'),
        QuotationAvailability.unavailable,
      );
    });

    test("override='auto' borda superior: 19:59 → available, 20:00 → unavailable", () {
      expect(
        computeQuotationAvailability(nowInSp: DateTime(2026, 7, 29, 19, 59, 0), adminOverride: 'auto'),
        QuotationAvailability.available,
      );
      expect(
        computeQuotationAvailability(nowInSp: at(20), adminOverride: 'auto'),
        QuotationAvailability.unavailable,
      );
    });

    test("override='force_enabled' + hora=3 → available", () {
      expect(
        computeQuotationAvailability(nowInSp: at(3), adminOverride: 'force_enabled'),
        QuotationAvailability.available,
      );
    });

    test("override='force_disabled' + hora=12 → unavailable", () {
      expect(
        computeQuotationAvailability(nowInSp: at(12), adminOverride: 'force_disabled'),
        QuotationAvailability.unavailable,
      );
    });

    test("override desconhecido cai no branch 'auto'", () {
      expect(
        computeQuotationAvailability(nowInSp: at(14), adminOverride: 'unknown'),
        QuotationAvailability.available,
      );
      expect(
        computeQuotationAvailability(nowInSp: at(3), adminOverride: 'unknown'),
        QuotationAvailability.unavailable,
      );
    });
  });
}
