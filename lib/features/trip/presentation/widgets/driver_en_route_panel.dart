import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/data/models/mock_driver.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverEnRoutePanel extends StatelessWidget {
  final MockDriver driver;
  final int etaMinutes;
  final int distanceMeters;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onCancel;
  final String? driverPhone;
  final VoidCallback? onOpenChat;
  final String? driverAvatarUrl;

  const DriverEnRoutePanel({
    super.key,
    required this.driver,
    required this.etaMinutes,
    this.distanceMeters = 0,
    this.isExpanded = false,
    required this.onToggleExpand,
    required this.onCancel,
    this.driverPhone,
    this.onOpenChat,
    this.driverAvatarUrl,
  });

  String get _distanceLabel {
    if (distanceMeters <= 0) return '';
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: isExpanded ? null : onToggleExpand,
      onVerticalDragUpdate: (d) {
        if (!isExpanded && d.delta.dy < -3) onToggleExpand();
        if (isExpanded && d.delta.dy > 3) onToggleExpand();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: isExpanded ? screenHeight * 0.55 : 160,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: isExpanded
            ? _buildExpandedContent()
            : _buildMinimizedContent(),
      ),
    );
  }

  Widget _buildMinimizedContent() {
    final firstName = driver.name.split(' ').first;
    final statusText = '$firstName está a caminho';

    return Column(
      children: [
        _buildGrabber(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildAvatar(44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${driver.carModel} • ${driver.carColor}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver.licensePlate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MiniCancelButton(onTap: onCancel),
                  if (etaMinutes > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.highlight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: AppColors.highlight),
                          const SizedBox(width: 4),
                          Text(
                            '$etaMinutes min',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.highlight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_distanceLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _distanceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.highlight.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        _buildGrabber(),
        _buildExpandedHeader(),
        _buildActionButtons(),
        Expanded(child: _buildDriverProfile()),
      ],
    );
  }

  Widget _buildExpandedHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildAvatar(52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.highlight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      driver.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (etaMinutes > 0)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.highlight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.highlight),
                      const SizedBox(width: 4),
                      Text(
                        '~$etaMinutes min',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.highlight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_distanceLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _distanceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.highlight.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.close_rounded,
              label: 'Cancelar',
              color: const Color(0xFFDC2626),
              onTap: onCancel,
            ),
          ),
          const SizedBox(width: 12),
          if (driverPhone != null) ...[
            Expanded(
              child: _ActionButton(
                icon: Icons.phone_rounded,
                label: 'Ligar',
                color: const Color(0xFF22C55E),
                onTap: () async {
                  final uri = Uri.parse('tel:$driverPhone');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _ActionButton(
              icon: Icons.chat_rounded,
              label: 'Chat',
              color: AppColors.highlight,
              onTap: () => onOpenChat?.call(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.directions_car_rounded,
              '${driver.carModel} • ${driver.carColor}'),
          const SizedBox(height: 8),
          _buildInfoRow(
              Icons.badge_rounded, 'Placa: ${driver.licensePlate}'),
          const SizedBox(height: 8),
          _buildInfoRow(
              Icons.credit_card_rounded, 'RG: ${driver.rg}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.cake_rounded,
              'Nascimento: ${driver.birthDate.day.toString().padLeft(2, '0')}/${driver.birthDate.month.toString().padLeft(2, '0')}/${driver.birthDate.year}'),
          const SizedBox(height: 16),
          const Text(
            'Sobre',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            driver.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Adicionais',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: driver.extras.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.highlight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.highlight,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(double size) {
    if (driverAvatarUrl != null && driverAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(driverAvatarUrl!),
        backgroundColor: AppColors.highlight.withValues(alpha: 0.15),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.highlight.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Text(
          driver.initials,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: AppColors.highlight,
          ),
        ),
      ),
    );
  }

  Widget _buildGrabber() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCancelButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MiniCancelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.2),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
