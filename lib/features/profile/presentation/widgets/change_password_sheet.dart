import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/edit_profile_widgets.dart';

/// Shows a bottom sheet for changing the user's password.
///
/// [onSave] should return `null` on success or an error message string.
Future<void> showChangePasswordSheet(
  BuildContext context, {
  required Future<String?> Function(String newPassword) onSave,
}) {
  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  String? errorText;
  bool isLoading = false;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Alterar Senha',
                style: TextStyle(
                  fontFamily: 'OutfitBlack',
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: currentPasswordCtrl,
                label: 'Senha atual',
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: newPasswordCtrl,
                label: 'Nova senha',
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: confirmPasswordCtrl,
                label: 'Confirmar nova senha',
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorText!,
                  style: const TextStyle(
                    fontFamily: 'QuasimodoSemiBold',
                    fontSize: 13,
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newPass = newPasswordCtrl.text;
                          final confirm = confirmPasswordCtrl.text;

                          if (currentPasswordCtrl.text.isEmpty ||
                              newPass.isEmpty ||
                              confirm.isEmpty) {
                            setSheetState(() {
                              errorText = 'Preencha todos os campos';
                            });
                            return;
                          }

                          if (newPass.length < 6) {
                            setSheetState(() {
                              errorText =
                                  'A nova senha deve ter pelo menos 6 caracteres';
                            });
                            return;
                          }

                          if (newPass != confirm) {
                            setSheetState(() {
                              errorText = 'As senhas não coincidem';
                            });
                            return;
                          }

                          setSheetState(() => isLoading = true);
                          final error = await onSave(newPass);
                          if (ctx.mounted) {
                            if (error == null) {
                              Navigator.pop(ctx);
                            } else {
                              setSheetState(() {
                                isLoading = false;
                                errorText = error;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Alterar Senha',
                          style: TextStyle(
                            fontFamily: 'QuasimodoSemiBold',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        ),
      ),
    ),
  );
}
