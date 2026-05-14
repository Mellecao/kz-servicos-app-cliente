import 'package:kz_servicos_app/features/auth/domain/entities/app_user.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithEmail {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }
}
