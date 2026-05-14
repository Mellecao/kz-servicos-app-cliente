import 'package:kz_servicos_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kz_servicos_app/features/auth/domain/entities/app_user.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final data = await _dataSource.signInWithEmail(
      email: email,
      password: password,
    );

    return AppUser(
      id: data['id'] as String,
      fullName: data['full_name'] as String,
      email: data['email'] as String,
      role: data['role'] as String,
      phone: data['phone'] as String?,
      avatarUrl: data['avatar_url'] as String?,
    );
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  @override
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final data = await _dataSource.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    if (data == null) return null;

    return AppUser(
      id: data['id'] as String,
      fullName: data['full_name'] as String,
      email: data['email'] as String,
      role: data['role'] as String,
      phone: data['phone'] as String?,
      avatarUrl: data['avatar_url'] as String?,
    );
  }
}
