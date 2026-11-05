import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/dark_system_ui.dart';

void main() {
  testWidgets('asks for light status bar icons and keeps the child',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DarkSystemUi(child: Text('conteúdo'))),
    );

    expect(find.text('conteúdo'), findsOneWidget);

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byWidgetPredicate(
        (w) =>
            w is AnnotatedRegion<SystemUiOverlayStyle> &&
            w.value.statusBarIconBrightness == Brightness.light,
      ),
    );
    expect(region.value.statusBarColor, Colors.transparent);
    expect(region.value.statusBarBrightness, Brightness.dark);
  });
}
