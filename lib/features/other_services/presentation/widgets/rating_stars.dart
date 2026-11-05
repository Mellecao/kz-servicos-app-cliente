import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumeric;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showNumeric = false,
  });

  static const _starColor = AppColors.highlight;

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < fullStars) {
            return Icon(Icons.star, size: size, color: _starColor);
          }
          if (index == fullStars && hasHalfStar) {
            return Icon(Icons.star_half, size: size, color: _starColor);
          }
          return Icon(Icons.star_border, size: size, color: _starColor);
        }),
        if (showNumeric) ...[
          SizedBox(width: size * 0.25),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5C5956),
            ),
          ),
        ],
      ],
    );
  }
}
