import 'package:kz_servicos_app/features/auth/domain/entities/app_user.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
  }) async {
    final user = await _repository.signInWithEmail(
      email: email,
      password: password,
    );

    if (user.role != 'client') {
      await _repository.signOut();
      throw NotClientException();
    }

    return user;
  }
}

class NotClientException implements Exception {
  @override
  String toString() => 'Esta aplicação é exclusiva para clientes';
}
