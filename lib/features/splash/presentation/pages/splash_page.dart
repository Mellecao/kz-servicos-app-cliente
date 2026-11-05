import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/widgets/brand_logo.dart';
import 'package:kz_servicos_app/core/widgets/dark_system_ui.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await context.read<AuthCubit>().restoreSession();
    if (!mounted) return;
    final state = context.read<AuthCubit>().state;
    if (state is AuthSuccess) {
      context.go('/trip');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const DarkSystemUi(
      child: Scaffold(
        backgroundColor: AppColors.brandDark,
        body: Center(child: BrandLogo(onDark: true, width: 260)),
      ),
    );
  }
}
