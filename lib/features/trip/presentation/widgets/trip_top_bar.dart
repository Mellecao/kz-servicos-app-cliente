import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class TripTopBar extends StatelessWidget {
  const TripTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAvatarButton(),
        _buildChatButton(),
      ],
    );
  }

  Widget _buildAvatarButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: AppColors.meshSlide1,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.highlight.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
    );
  }

  Widget _buildChatButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: Colors.black87,
        size: 22,
      ),
    );
  }
}
