import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/core/widgets/brand_backdrop.dart';
import 'package:kz_servicos_app/core/widgets/brand_logo.dart';
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

      expect(find.text('Iniciar sessão'), findsOneWidget);
    });

    testWidgets('should display "Cadastre-se" button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets('should have two main action buttons', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('should show the Só Serviços logo on a dark backdrop',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      final logo = tester.widget<BrandLogo>(find.byType(BrandLogo));
      expect(logo.onDark, isTrue);
      expect(find.byType(BrandBackdrop), findsOneWidget);
    });

    testWidgets('should not use the legacy KZ illustration', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName);
      expect(assets, isNot(contains('public/assets/bg_login.png')));
    });

    testWidgets('should use Stack layout', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('login button should open bottom sheet', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Iniciar sessão'));
      await tester.pumpAndSettle();

      expect(find.text('Aceda à sua conta'), findsOneWidget);
    });

    testWidgets('register button should open bottom sheet', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Crie a sua conta'), findsOneWidget);
    });

    testWidgets('login bottom sheet should have email and password fields',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Iniciar sessão'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Palavra-passe'), findsOneWidget);
    });
  });
}
