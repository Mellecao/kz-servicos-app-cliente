import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/core/utils/phone_input_formatter.dart';
import 'package:kz_servicos_app/features/auth/presentation/widgets/apple_sign_in_button.dart';
import 'package:kz_servicos_app/features/auth/presentation/widgets/google_sign_in_button.dart';

enum AuthMode { login, register, forgotPassword }

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({
    required this.initialMode,
    super.key,
  });

  final AuthMode initialMode;

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  late AuthMode _mode;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthMode.login
          ? AuthMode.register
          : AuthMode.login;
    });
  }

  void _goToForgotPassword() {
    setState(() => _mode = AuthMode.forgotPassword);
  }

  void _goToLogin() {
    setState(() => _mode = AuthMode.login);
  }

  bool get _isLogin => _mode == AuthMode.login;
  bool get _isForgotPassword => _mode == AuthMode.forgotPassword;

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
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 28),
              ..._buildFields(),
              if (_isLogin) ...[
                const SizedBox(height: 4),
                _buildForgotPassword(),
              ],
              const SizedBox(height: 24),
              _buildPrimaryButton(),
              if (!_isForgotPassword) ...[
                const SizedBox(height: 12),
                GoogleSignInButton(
                  onPressed: () {},
                  label: _isLogin
                      ? 'Login com Google'
                      : 'Registrar-se com Google',
                ),
                const SizedBox(height: 12),
                AppleSignInButton(
                  onPressed: () {},
                  label: _isLogin
                      ? 'Login com Apple'
                      : 'Registrar-se com Apple',
                ),
              ],
              const SizedBox(height: 16),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildSecondaryButton(),
            ],
          ),
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
    String title;
    String subtitle;
    switch (_mode) {
      case AuthMode.login:
        title = 'Login';
        subtitle = 'Acesse sua conta';
      case AuthMode.register:
        title = 'Cadastre-se';
        subtitle = 'Crie sua conta';
      case AuthMode.forgotPassword:
        title = 'Recuperar senha';
        subtitle = 'Informe seu e-mail';
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(_mode),
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyBody,
              fontSize: 15,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFields() {
    if (_isForgotPassword) {
      return [
        _buildEmailField(),
      ];
    }
    if (_isLogin) {
      return [
        _buildEmailField(),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ];
    }
    return [
      _buildTextField(
        controller: _nameController,
        hint: 'Nome',
        icon: Icons.person_outline,
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 16),
      _buildEmailField(),
      const SizedBox(height: 16),
      _buildPhoneField(),
      const SizedBox(height: 16),
      _buildPasswordField(),
    ];
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
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
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        PhoneInputFormatter(),
      ],
      style: _fieldTextStyle(),
      decoration: _inputDecoration(
        hint: 'Telefone',
        icon: Icons.phone_outlined,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: _fieldTextStyle(),
      decoration: _inputDecoration(hint: hint, icon: icon),
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

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _goToForgotPassword,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Esqueci minha senha',
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyBody,
            fontSize: 14,
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
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
        child: Text(_primaryButtonLabel()),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isForgotPassword ? _goToLogin : _toggleMode,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          side: BorderSide(color: Colors.grey[300]!, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontFamily: AppTheme.fontFamilyBody,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(_secondaryButtonLabel()),
      ),
    );
  }

  String _primaryButtonLabel() {
    switch (_mode) {
      case AuthMode.login:
        return 'Login';
      case AuthMode.register:
        return 'Registrar-se';
      case AuthMode.forgotPassword:
        return 'Enviar e-mail';
    }
  }

  String _secondaryButtonLabel() {
    switch (_mode) {
      case AuthMode.login:
        return 'Registrar-se';
      case AuthMode.register:
        return 'Já tenho conta';
      case AuthMode.forgotPassword:
        return 'Fazer login';
    }
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
