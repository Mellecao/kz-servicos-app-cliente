import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_ui.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sheetBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pedido enviado!',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyTitle,
                  fontSize: 24,
                  color: AppColors.sheetTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Recebemos o seu pedido. Vai receber uma notificação quando '
                'for confirmado e quando sair para entrega.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.sheetTextSecondary,
                ),
              ),
              const Spacer(),
              PrimaryActionButton(
                label: 'Acompanhar o pedido',
                onPressed: () {
                  context.go('/services');
                  context.push('/products/orders/$orderId');
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const Key('success_done'),
                onPressed: () => context.go('/services'),
                child: const Text(
                  'Concluir',
                  style: TextStyle(color: AppColors.highlight, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
