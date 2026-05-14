import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/routes/app_router.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AppRouter', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit(
        signInWithEmail: MockSignInWithEmail(),
        signUpWithEmail: MockSignUpWithEmail(),
        repository: MockAuthRepository(),
      );
    });

    tearDown(() => authCubit.close());

    test('should have splash as initial route', () {
      final router = AppRouter.createRouter(authCubit);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/splash',
      );
    });

    test('router should not be null', () {
      expect(AppRouter.createRouter(authCubit), isNotNull);
    });
  });
}
