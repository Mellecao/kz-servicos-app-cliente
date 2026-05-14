import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

export 'package:kz_servicos_app/features/profile/presentation/widgets/change_password_sheet.dart';

/// Shows a bottom sheet for editing a single profile field.
///
/// [onSave] should return `null` on success or an error message string.
Future<void> showEditFieldSheet(
  BuildContext context, {
  required String title,
  required String initialValue,
  required Future<String?> Function(String value) onSave,
  TextInputType keyboardType = TextInputType.text,
}) {
  final controller = TextEditingController(text: initialValue);
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
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'OutfitBlack',
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: title.replaceFirst('Alterar ', ''),
                  labelStyle: const TextStyle(
                    fontFamily: 'QuasimodoSemiBold',
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                  errorText: errorText,
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) {
                            setSheetState(() => errorText = 'Campo obrigatório');
                            return;
                          }
                          if (value == initialValue) {
                            Navigator.pop(ctx);
                            return;
                          }

                          setSheetState(() => isLoading = true);
                          final error = await onSave(value);
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
                          'Salvar',
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
