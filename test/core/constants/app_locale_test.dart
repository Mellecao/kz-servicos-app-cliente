import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/constants/app_locale.dart';

Future<MaterialLocalizations> _localizations(WidgetTester tester) async {
  late MaterialLocalizations result;
  await tester.pumpWidget(
    MaterialApp(
      locale: AppLocale.locale,
      supportedLocales: AppLocale.supported,
      localizationsDelegates: AppLocale.delegates,
      home: Builder(
        builder: (context) {
          result = MaterialLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('AppLocale', () {
    test('uses European Portuguese because intl has no pt_AO', () {
      expect(AppLocale.locale, const Locale('pt', 'PT'));
      expect(AppLocale.supported, [const Locale('pt', 'PT')]);
    });

    testWidgets('Material widgets speak Portuguese', (tester) async {
      final l10n = await _localizations(tester);

      expect(l10n.cancelButtonLabel, 'Cancelar');
      expect(l10n.okButtonLabel, 'OK');
    });

    testWidgets('times are shown in 24 h', (tester) async {
      final l10n = await _localizations(tester);

      expect(l10n.formatTimeOfDay(const TimeOfDay(hour: 15, minute: 30)), '15:30');
      expect(l10n.formatTimeOfDay(const TimeOfDay(hour: 7, minute: 5)), '07:05');
    });

    testWidgets('dates are shown day first', (tester) async {
      final l10n = await _localizations(tester);

      expect(l10n.formatCompactDate(DateTime(2026, 11, 5)), '05/11/2026');
    });
  });
}
