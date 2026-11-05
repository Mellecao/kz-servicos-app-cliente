import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/widgets/auth_bottom_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthCubit authCubit;
  late MockSignUpWithEmail mockSignUp;

  setUp(() {
    mockSignUp = MockSignUpWithEmail();
    authCubit = AuthCubit(
      signInWithEmail: MockSignInWithEmail(),
      signUpWithEmail: mockSignUp,
      repository: MockAuthRepository(),
    );
    when(
      () => mockSignUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        fullName: any(named: 'fullName'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async => null);
  });

  tearDown(() => authCubit.close());

  Future<void> openRegister(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: const MaterialApp(
          home: Scaffold(
            body: AuthBottomSheet(initialMode: AuthMode.register),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(WidgetTester tester, {required String phone}) async {
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Maria');
    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail'),
      'maria@exemplo.com',
    );
    if (phone.isNotEmpty) {
      await tester.enterText(find.widgetWithText(TextField, 'Telemóvel'), phone);
    }
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
  }

  group('AuthBottomSheet phone (register)', () {
    testWidgets('shows the +244 prefix and the Telemóvel hint', (tester) async {
      await openRegister(tester);

      expect(find.text('+244'), findsOneWidget);
      expect(find.text('Telemóvel'), findsOneWidget);
    });

    testWidgets('formats the typed number as 9XX XXX XXX', (tester) async {
      await openRegister(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Telemóvel'),
        '912345678',
      );

      expect(find.text('912 345 678'), findsOneWidget);
    });

    testWidgets('blocks sign-up and explains when the number is invalid',
        (tester) async {
      await openRegister(tester);

      await fillAndSubmit(tester, phone: '812345678');

      expect(
        find.text('Introduza um número de telemóvel válido (9 dígitos).'),
        findsOneWidget,
      );
      verifyNever(
        () => mockSignUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
        ),
      );
    });

    testWidgets('saves a valid number as E.164 without spaces', (tester) async {
      await openRegister(tester);

      await fillAndSubmit(tester, phone: '923000001');

      verify(
        () => mockSignUp(
          email: 'maria@exemplo.com',
          password: '123456',
          fullName: 'Maria',
          phone: '+244923000001',
        ),
      ).called(1);
    });

    testWidgets('keeps the phone optional', (tester) async {
      await openRegister(tester);

      await fillAndSubmit(tester, phone: '');

      verify(
        () => mockSignUp(
          email: 'maria@exemplo.com',
          password: '123456',
          fullName: 'Maria',
          phone: '',
        ),
      ).called(1);
    });
  });
}
