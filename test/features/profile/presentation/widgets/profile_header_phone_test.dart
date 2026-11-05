import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/profile_header.dart';

Widget _host(String? phone) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ProfileHeader(
          name: 'Miguel M',
          email: 'miguelm@cliente.com',
          phone: phone,
        ),
      ),
    ),
  );
}

void main() {
  group('ProfileHeader phone', () {
    testWidgets('shows a stored E.164 number as +244 9XX XXX XXX',
        (tester) async {
      await tester.pumpWidget(_host('+244923000001'));

      expect(find.text('+244 923 000 001'), findsOneWidget);
      expect(find.text('+244923000001'), findsNothing);
    });

    testWidgets('leaves a legacy number exactly as stored', (tester) async {
      await tester.pumpWidget(_host('+5511999999999'));

      expect(find.text('+5511999999999'), findsOneWidget);
    });

    testWidgets('shows nothing when there is no phone', (tester) async {
      await tester.pumpWidget(_host(null));

      expect(find.textContaining('+244'), findsNothing);
    });
  });
}
