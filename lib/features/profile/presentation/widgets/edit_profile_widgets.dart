import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class ProfileSection extends StatelessWidget {
  final List<ProfileItem> items;

  const ProfileSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
              ),
            items[i],
          ],
        ],
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.highlight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.highlight, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: const TextStyle(
        fontFamily: 'QuasimodoSemiBold',
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(
          fontFamily: 'QuasimodoSemiBold',
          fontSize: 14,
          color: Color(0xFF999999),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.highlight,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: const Color(0xFF999999),
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class DeleteAccountButton extends StatelessWidget {
  final VoidCallback onTap;

  const DeleteAccountButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Excluir Conta',
              style: TextStyle(
                fontFamily: 'QuasimodoSemiBold',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
