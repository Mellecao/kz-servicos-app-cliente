import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, role, phone, avatarUrl];
}
