import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, SupabaseClient;

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user?.id;
    if (userId == null) {
      throw Exception('Falha na autenticação');
    }

    final userData =
        await _client.from('users').select().eq('id', userId).single();
    return userData;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone.isNotEmpty ? phone : null,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Falha ao criar conta');
    }

    if (user.identities == null || user.identities!.isEmpty) {
      throw AuthException('User already registered');
    }

    if (response.session == null) {
      return null;
    }

    return {
      'id': user.id,
      'full_name': fullName,
      'email': email,
      'phone': phone.isNotEmpty ? phone : null,
      'role': 'client',
      'avatar_url': null,
    };
  }
}
