import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? phone;
  final double profileCompletion;
  final bool hasNotifications;
  final VoidCallback? onBackTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onEditPhotoTap;
  final String? avatarPath;
  final String? avatarUrl;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.phone,
    this.profileCompletion = 0.0,
    this.hasNotifications = false,
    this.onBackTap,
    this.onNotificationsTap,
    this.onEditPhotoTap,
    this.avatarPath,
    this.avatarUrl,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          _buildAvatar(),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'OutfitBlack',
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontFamily: 'QuasimodoSemiBold',
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
          if (phone != null && phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone!,
              style: const TextStyle(
                fontFamily: 'QuasimodoSemiBold',
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onBackTap,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 22,
            color: Color(0xFF999999),
          ),
        ),
        GestureDetector(
          onTap: onNotificationsTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 24,
                color: Color(0xFF999999),
              ),
              if (hasNotifications)
                const Positioned(
                  top: -2,
                  right: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 8, height: 8),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    const double avatarRadius = 45;
    const double ringWidth = 3;
    const double totalSize = (avatarRadius + ringWidth) * 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: totalSize,
          height: totalSize,
          child: CustomPaint(
            painter: _ProgressRingPainter(progress: profileCompletion),
            child: Center(
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.secondary,
                backgroundImage: _avatarImage,
                child: _avatarImage == null
                    ? Text(
                        _initials,
                        style: const TextStyle(
                          fontFamily: 'OutfitBlack',
                          fontSize: 24,
                          color: AppColors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEditPhotoTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.highlight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? get _avatarImage {
    if (avatarPath != null) {
      if (kIsWeb) return NetworkImage(avatarPath!);
      return FileImage(File(avatarPath!));
    }
    if (avatarUrl != null) return NetworkImage(avatarUrl!);
    return null;
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.5;
    const strokeWidth = 3.0;
    const startAngle = -pi / 2;

    // Background circle (light grey)
    final bgPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: const [AppColors.secondary, AppColors.highlight],
      transform: const GradientRotation(-pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
