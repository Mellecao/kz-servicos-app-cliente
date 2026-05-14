import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:kz_servicos_app/features/auth/presentation/pages/login_page.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthCubit authCubit;
  late MockSignInWithEmail mockSignIn;
  late MockSignUpWithEmail mockSignUp;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockSignIn = MockSignInWithEmail();
    mockSignUp = MockSignUpWithEmail();
    mockRepository = MockAuthRepository();
    authCubit = AuthCubit(
      signInWithEmail: mockSignIn,
      signUpWithEmail: mockSignUp,
      repository: mockRepository,
    );
  });

  tearDown(() => authCubit.close());

  Widget buildApp({Widget? home}) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(home: home ?? const LoginPage()),
    );
  }

  group('LoginPage', () {
    testWidgets('should display "Login" button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should display "Cadastre-se" button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cadastre-se'), findsOneWidget);
    });

    testWidgets('should have two main action buttons', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('should contain background image', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should use Stack layout', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('login button should open bottom sheet', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Acesse sua conta'), findsOneWidget);
    });

    testWidgets('register button should open bottom sheet', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();

      expect(find.text('Crie sua conta'), findsOneWidget);
    });

    testWidgets('login bottom sheet should have email and password fields',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });
  });
}
