import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/auth/domain/entities/app_user.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthCubit cubit;
  late MockSignInWithEmail mockSignIn;
  late MockSignUpWithEmail mockSignUp;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockSignIn = MockSignInWithEmail();
    mockSignUp = MockSignUpWithEmail();
    mockRepository = MockAuthRepository();
    cubit = AuthCubit(
      signInWithEmail: mockSignIn,
      signUpWithEmail: mockSignUp,
      repository: mockRepository,
    );
  });

  tearDown(() => cubit.close());

  const testUser = AppUser(
    id: '123',
    fullName: 'Ana Carolina',
    email: 'ana@email.com',
    role: 'client',
  );

  group('AuthCubit signIn', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () {
        when(() => mockSignIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => testUser);
        return cubit;
      },
      act: (cubit) => cubit.signIn(
        email: 'ana@email.com',
        password: '123456',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthSuccess(testUser),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthError] when email is empty',
      build: () => cubit,
      act: (cubit) => cubit.signIn(email: '', password: '123456'),
      expect: () => [
        const AuthError('Preencha todos os campos'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthError] when password is empty',
      build: () => cubit,
      act: (cubit) => cubit.signIn(email: 'ana@email.com', password: ''),
      expect: () => [
        const AuthError('Preencha todos os campos'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthError] when email is invalid',
      build: () => cubit,
      act: (cubit) => cubit.signIn(email: 'invalid-email', password: '123456'),
      expect: () => [
        const AuthError('Informe um e-mail válido'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when user is not client',
      build: () {
        when(() => mockSignIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(NotClientException());
        return cubit;
      },
      act: (cubit) => cubit.signIn(
        email: 'joao@email.com',
        password: '123456',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Este aplicativo é exclusivo para clientes'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] with translated message on invalid credentials',
      build: () {
        when(() => mockSignIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Invalid login credentials'));
        return cubit;
      },
      act: (cubit) => cubit.signIn(
        email: 'wrong@email.com',
        password: 'wrong',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('E-mail ou senha incorretos'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] on generic exception',
      build: () {
        when(() => mockSignIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(Exception('Network error'));
        return cubit;
      },
      act: (cubit) => cubit.signIn(
        email: 'test@email.com',
        password: '123456',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Erro ao fazer login. Tente novamente.'),
      ],
    );
  });

  group('AuthCubit signOut', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthInitial] when signOut succeeds',
      build: () {
        when(() => mockRepository.signOut()).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.signOut(),
      expect: () => [
        const AuthInitial(),
      ],
      verify: (_) {
        verify(() => mockRepository.signOut()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthInitial] even when signOut throws',
      build: () {
        when(() => mockRepository.signOut())
            .thenAnswer((_) async => throw Exception('Network error'));
        return cubit;
      },
      act: (cubit) => cubit.signOut(),
      expect: () => [
        const AuthInitial(),
      ],
      errors: () => [isA<Exception>()],
    );
  });
}
