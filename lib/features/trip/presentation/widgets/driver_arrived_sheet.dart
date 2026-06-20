import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverArrivedSheet extends StatefulWidget {
  final String driverName;
  final String? pickupAddress;
  final String? destinationAddress;
  final double? offeredPrice;
  final int? passengerCount;
  final String? driverPhone;
  final VoidCallback? onOpenChat;
  final String? driverAvatarUrl;

  const DriverArrivedSheet({
    super.key,
    required this.driverName,
    this.pickupAddress,
    this.destinationAddress,
    this.offeredPrice,
    this.passengerCount,
    this.driverPhone,
    this.onOpenChat,
    this.driverAvatarUrl,
  });

  @override
  State<DriverArrivedSheet> createState() => _DriverArrivedSheetState();
}

class _DriverArrivedSheetState extends State<DriverArrivedSheet> {
  bool _detailsOpen = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.driverName} chegou ao local de embarque',
                      style: const TextStyle(
                        fontFamily: 'QuasimodoSemiBold',
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (widget.pickupAddress != null)
                      Text(
                        'Dirija-se até ${widget.pickupAddress}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary.withValues(alpha: 0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.driverPhone != null) ...[
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone_rounded,
                    label: 'Ligar',
                    color: const Color(0xFF22C55E),
                    onTap: () async {
                      final uri = Uri.parse('tel:${widget.driverPhone}');
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
                  onTap: () => widget.onOpenChat?.call(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _detailsOpen = !_detailsOpen),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    'Detalhes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _detailsOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_detailsOpen) ...[
            const SizedBox(height: 4),
            _detailRow(
              Icons.my_location,
              'Origem',
              widget.pickupAddress ?? '—',
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.location_on_outlined,
              'Destino',
              widget.destinationAddress ?? '—',
            ),
            if (widget.passengerCount != null) ...[
              const SizedBox(height: 8),
              _detailRow(
                Icons.people_outline,
                'Passageiros',
                '${widget.passengerCount}',
              ),
            ],
            if (widget.offeredPrice != null) ...[
              const SizedBox(height: 8),
              _detailRow(
                Icons.attach_money,
                'Valor',
                'R\$ ${widget.offeredPrice!.toStringAsFixed(2)}',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    const size = 44.0;
    final avatarUrl = widget.driverAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: const Color(0xFF2ECC71).withValues(alpha: 0.12),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.directions_car_rounded,
        color: Color(0xFF2ECC71),
        size: 22,
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
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
