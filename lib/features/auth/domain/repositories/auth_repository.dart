import 'package:kz_servicos_app/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  Future<void> signOut();
}
