import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/auth/presentation/widgets/apple_sign_in_button.dart';
import 'package:kz_servicos_app/features/auth/presentation/widgets/google_sign_in_button.dart';

class RegisterBottomSheet extends StatefulWidget {
  const RegisterBottomSheet({super.key});

  @override
  State<RegisterBottomSheet> createState() => _RegisterBottomSheetState();
}

class _RegisterBottomSheetState extends State<RegisterBottomSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const SizedBox(height: 24),
            _buildHeader(),
            const SizedBox(height: 28),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 28),
            _buildRegisterButton(),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            GoogleSignInButton(
              onPressed: () {},
              label: 'Registrar-se com Google',
            ),
            const SizedBox(height: 12),
            AppleSignInButton(
              onPressed: () {},
              label: 'Registrar-se com Apple',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Cadastre-se',
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyTitle,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Crie sua conta',
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyBody,
            fontSize: 15,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      style: _fieldTextStyle(),
      decoration: _inputDecoration(
        hint: 'Nome',
        icon: Icons.person_outline,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: _fieldTextStyle(),
      decoration: _inputDecoration(
        hint: 'E-mail',
        icon: Icons.email_outlined,
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: _fieldTextStyle(),
      decoration: _inputDecoration(
        hint: 'Telefone',
        icon: Icons.phone_outlined,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: _fieldTextStyle(),
      decoration: _inputDecoration(
        hint: 'Senha',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[400],
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {},
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
        child: const Text('Registrar-se'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyBody,
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  TextStyle _fieldTextStyle() {
    return TextStyle(
      fontFamily: AppTheme.fontFamilyBody,
      fontSize: 15,
      color: const Color(0xFF1A1A1A),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamilyBody,
        color: Colors.grey[400],
        fontSize: 15,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F7F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.highlight,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
      suffixIcon: suffixIcon,
    );
  }
}
