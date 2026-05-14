import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/splash/presentation/pages/splash_page.dart';
import 'package:kz_servicos_app/routes/app_router.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('KzServicosApp renders without crashing',
      (WidgetTester tester) async {
    final mockSignIn = MockSignInWithEmail();
    final mockSignUp = MockSignUpWithEmail();
    final mockRepository = MockAuthRepository();
    final authCubit = AuthCubit(
      signInWithEmail: mockSignIn,
      signUpWithEmail: mockSignUp,
      repository: mockRepository,
    );

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: MaterialApp.router(
          title: 'KZ Serviços',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: AppRouter.createRouter(authCubit),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    // Advance past splash timer to avoid pending timer warning
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    authCubit.close();
  });
}
