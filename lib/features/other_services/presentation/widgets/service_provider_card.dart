import 'package:flutter/material.dart';

import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';

/// Prestador escolhido + preço final (em Kz), com dados reais do pedido.
class ServiceProviderCard extends StatelessWidget {
  const ServiceProviderCard({
    super.key,
    required this.provider,
    this.finalPrice,
    this.priceLabel = 'Preço final',
  });

  final ServiceProvider provider;
  final double? finalPrice;
  final String priceLabel;

  String get _initial =>
      provider.name.trim().isEmpty ? '?' : provider.name.trim()[0].toUpperCase();

  String? get _ratingText {
    final rating = provider.rating;
    if (rating == null || provider.totalRatings == 0) return null;
    final value = rating.toStringAsFixed(1).replaceAll('.', ',');
    final n = provider.totalRatings;
    return '$value ★ · $n ${n == 1 ? 'avaliação' : 'avaliações'}';
  }

  @override
  Widget build(BuildContext context) {
    final avatar = provider.avatarUrl;
    return Container(
      key: const Key('service_provider_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.highlightSoft,
                foregroundImage: avatar == null || avatar.isEmpty
                    ? null
                    : NetworkImage(avatar),
                child: Text(
                  _initial,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamilyTitle,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_ratingText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _ratingText!,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (finalPrice != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  priceLabel,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  formatKz(finalPrice!),
                  key: const Key('service_final_price'),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyTitle,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
