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
    fullName: 'Maria Silva',
    email: 'maria@email.com',
    role: 'client',
    phone: '(11) 99999-9999',
  );

  group('AuthCubit signUp', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthSuccess] when signup succeeds with session',
      build: () {
        when(() => mockSignUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
            )).thenAnswer((_) async => testUser);
        return cubit;
      },
      act: (cubit) => cubit.signUp(
        name: 'Maria Silva',
        email: 'maria@email.com',
        phone: '(11) 99999-9999',
        password: '123456',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthSuccess(testUser),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthEmailConfirmationSent] when email confirmation is required',
      build: () {
        when(() => mockSignUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
            )).thenAnswer((_) async => null);
        return cubit;
      },
      act: (cubit) => cubit.signUp(
        name: 'Maria Silva',
        email: 'maria@email.com',
        phone: '(11) 99999-9999',
        password: '123456',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthEmailConfirmationSent(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthError] when name is empty',
      build: () => cubit,
      act: (cubit) => cubit.signUp(
        name: '',
        email: 'maria@email.com',
        phone: '',
        password: '123456',
      ),
      expect: () => [
        const AuthError('Preencha todos os campos obrigatórios'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthError] when email is empty',
      build: () => cubit,
      act: (cubit) => cubit.signUp(
        name: 'Maria',
        email: '',
        phone: '',
        password: '123456',
      ),
      expect: () => [
        const AuthError('Preencha todos os campos obrigatórios'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthError] when password is empty',
      build: () => cubit,
      act: (cubit) => cubit.signUp(
        name: 'Maria',
        email: 'maria@email.com',
        phone: '',
        password: '',
      ),
      expect: () => [
        const AuthError('Preencha todos os campos obrigatórios'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthError] when email is invalid',
      build: () => cubit,
      act: (cubit) => cubit.signUp(
        name: 'Maria',
        email: 'invalid-email',
        phone: '',
        password: '123456',
      ),
      expect: () => [
        const AuthError('Informe um e-mail válido'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthError] when password is too short',
      build: () => cubit,
      act: (cubit) => cubit.signUp(
        name: 'Maria',
        email: 'maria@email.com',
        phone: '',
        password: '123',
      ),
      expect: () => [
        const AuthError('A senha deve ter pelo menos 6 caracteres'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when user already registered',
      build: () {
        when(() => mockSignUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
            )).thenThrow(AuthException('User already registered'));
        return cubit;
      },
      act: (cubit) => cubit.signUp(
        name: 'Maria',
        email: 'maria@email.com',
        phone: '',
        password: '123456',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Este e-mail já está cadastrado'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] on generic exception',
      build: () {
        when(() => mockSignUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
            )).thenThrow(Exception('Network error'));
        return cubit;
      },
      act: (cubit) => cubit.signUp(
        name: 'Maria',
        email: 'maria@email.com',
        phone: '',
        password: '123456',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Erro ao criar conta. Tente novamente.'),
      ],
    );
  });
}
