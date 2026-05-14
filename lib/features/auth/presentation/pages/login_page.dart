import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:kz_servicos_app/features/auth/presentation/widgets/auth_bottom_sheet.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Bem-vindo(a), ${state.user.fullName}!',
                ),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 2),
              ),
            );
          context.go('/trip');
        } else if (state is AuthEmailConfirmationSent) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Text(
                  'Conta criada! Verifique seu e-mail para confirmar.',
                ),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 4),
              ),
            );
        }
        // Errors are handled inline in the bottom sheet
      },
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_background_img.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.4, 0.7],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 16),
                  FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Column(
                      children: [
                        _buildLoginButton(context),
                        const SizedBox(height: 14),
                        _buildRegisterButton(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _showLoginSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight,
          foregroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontFamily: AppTheme.fontFamilyBody,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
        child: const Text('Login'),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => _showRegisterSheet(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontFamily: AppTheme.fontFamilyBody,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Cadastre-se'),
      ),
    );
  }

  void _showLoginSheet(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: authCubit,
        child: const AuthBottomSheet(initialMode: AuthMode.login),
      ),
    );
  }

  void _showRegisterSheet(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: authCubit,
        child: const AuthBottomSheet(initialMode: AuthMode.register),
      ),
    );
  }
}
