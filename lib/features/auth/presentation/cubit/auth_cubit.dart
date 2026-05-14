import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/auth/domain/entities/app_user.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required SignInWithEmail signInWithEmail,
    required SignUpWithEmail signUpWithEmail,
    required AuthRepository repository,
  })  : _signInWithEmail = signInWithEmail,
        _signUpWithEmail = signUpWithEmail,
        _repository = repository,
        super(const AuthInitial());

  final SignInWithEmail _signInWithEmail;
  final SignUpWithEmail _signUpWithEmail;
  final AuthRepository _repository;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      emit(const AuthError('Preencha todos os campos'));
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      emit(const AuthError('Informe um e-mail válido'));
      return;
    }

    emit(const AuthLoading());

    try {
      final user = await _signInWithEmail(
        email: email,
        password: password,
      );
      emit(AuthSuccess(user));
    } on NotClientException {
      emit(const AuthError('Este aplicativo é exclusivo para clientes'));
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } on Exception {
      emit(const AuthError('Erro ao fazer login. Tente novamente.'));
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-mail ou senha incorretos';
    }
    if (message.contains('Email not confirmed')) {
      return 'E-mail não confirmado. Verifique sua caixa de entrada.';
    }
    return 'Erro ao fazer login. Tente novamente.';
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } finally {
      emit(const AuthInitial());
    }
  }

  void updateUser(AppUser user) {
    emit(AuthSuccess(user));
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      emit(const AuthError('Preencha todos os campos obrigatórios'));
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      emit(const AuthError('Informe um e-mail válido'));
      return;
    }

    if (password.length < 6) {
      emit(const AuthError('A senha deve ter pelo menos 6 caracteres'));
      return;
    }

    emit(const AuthLoading());

    try {
      final user = await _signUpWithEmail(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
      );
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthEmailConfirmationSent());
      }
    } on AuthException catch (e, st) {
      debugPrint('[AuthCubit.signUp] AuthException: ${e.message}');
      debugPrint('[AuthCubit.signUp] StackTrace: $st');
      emit(AuthError(_mapSignUpError(e.message)));
    } on Exception catch (e, st) {
      debugPrint('[AuthCubit.signUp] Exception: $e');
      debugPrint('[AuthCubit.signUp] StackTrace: $st');
      emit(const AuthError('Erro ao criar conta. Tente novamente.'));
    }
  }

  String _mapSignUpError(String message) {
    if (message.contains('User already registered')) {
      return 'Este e-mail já está cadastrado';
    }
    if (message.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (message.contains('password')) {
      return 'Senha muito fraca. Use pelo menos 6 caracteres.';
    }
    return 'Erro ao criar conta. Tente novamente.';
  }
}
