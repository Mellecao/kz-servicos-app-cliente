import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/edit_profile_sheets.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/edit_profile_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, Supabase, UserAttributes;

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _client = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthSuccess ? authState.user : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildHeader(context),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ProfileSection(
                        items: [
                          ProfileItem(
                            icon: Icons.person_rounded,
                            label: 'Alterar Nome',
                            subtitle: user?.fullName ?? '',
                            onTap: () => showEditFieldSheet(
                              context,
                              title: 'Alterar Nome',
                              initialValue: user?.fullName ?? '',
                              onSave: (v) => _updateField('full_name', v),
                            ),
                          ),
                          ProfileItem(
                            icon: Icons.email_rounded,
                            label: 'Alterar E-mail',
                            subtitle: user?.email ?? '',
                            onTap: () => showEditFieldSheet(
                              context,
                              title: 'Alterar E-mail',
                              initialValue: user?.email ?? '',
                              onSave: (v) => _updateField('email', v),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          ProfileItem(
                            icon: Icons.phone_rounded,
                            label: 'Alterar Telefone',
                            subtitle: user?.phone ?? 'Não informado',
                            onTap: () => showEditFieldSheet(
                              context,
                              title: 'Alterar Telefone',
                              initialValue: user?.phone ?? '',
                              onSave: (v) => _updateField('phone', v),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ProfileSection(
                        items: [
                          ProfileItem(
                            icon: Icons.lock_rounded,
                            label: 'Alterar Senha',
                            subtitle: 'Atualize sua senha de acesso',
                            onTap: () => showChangePasswordSheet(
                              context,
                              onSave: _updatePassword,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      DeleteAccountButton(
                        onTap: () => _showDeleteConfirmation(context),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Edição de Perfil',
              style: TextStyle(
                fontFamily: 'OutfitBlack',
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _updateField(String field, String value) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return 'Usuário não autenticado';
    final user = authState.user;

    try {
      await _client.from('users').update({field: value}).eq('id', user.id);

      final updated = switch (field) {
        'full_name' => user.copyWith(fullName: value),
        'email' => user.copyWith(email: value),
        'phone' => user.copyWith(phone: value),
        _ => user,
      };

      if (mounted) {
        context.read<AuthCubit>().updateUser(updated);
        _showSuccessSnackBar('Dados atualizados com sucesso!');
      }
      return null;
    } on Exception catch (e) {
      return 'Erro ao atualizar: ${e.toString()}';
    }
  }

  Future<String?> _updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        _showSuccessSnackBar('Senha alterada com sucesso!');
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } on Exception catch (e) {
      return 'Erro ao alterar senha: ${e.toString()}';
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Excluir Conta',
          style: TextStyle(
            fontFamily: 'OutfitBlack',
            fontSize: 18,
            color: Colors.red,
          ),
        ),
        content: const Text(
          'Tem certeza que deseja excluir sua conta? '
          'Esta ação não pode ser desfeita e todos os seus dados serão '
          'permanentemente removidos.',
          style: TextStyle(
            fontFamily: 'QuasimodoSemiBold',
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'QuasimodoSemiBold',
                color: Color(0xFF999999),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Solicitação de exclusão enviada.',
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Excluir',
              style: TextStyle(
                fontFamily: 'QuasimodoSemiBold',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
