import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/routes/app_router.dart';

void main() {
  group('AppRouter', () {
    test('should have onboarding as initial route', () {
      final router = AppRouter.router;
      expect(
        router.routeInformationProvider.value.uri.path,
        '/onboarding',
      );
    });

    test('router should not be null', () {
      expect(AppRouter.router, isNotNull);
    });
  });
}
