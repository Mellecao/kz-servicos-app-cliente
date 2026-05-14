import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/profile/data/models/mock_trip_history.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/scheduled_trip_widget.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/trip_history_card.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_details_sheet.dart';

class SettingsList extends StatefulWidget {
  final List<ScheduledTrip> scheduledTrips;
  final List<MockTripHistory> tripHistory;
  final VoidCallback? onScheduledTripDetailsTap;
  final VoidCallback? onSecurityTap;
  final VoidCallback? onHistoryTripTap;
  final VoidCallback? onViewAllScheduledTap;

  const SettingsList({
    super.key,
    required this.scheduledTrips,
    required this.tripHistory,
    this.onScheduledTripDetailsTap,
    this.onSecurityTap,
    this.onHistoryTripTap,
    this.onViewAllScheduledTap,
  });

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  int? _expandedIndex;

  bool get _hasPendingTrips => widget.scheduledTrips.isNotEmpty;

  ScheduledTrip? get _nextTrip {
    if (widget.scheduledTrips.isEmpty) return null;
    final sorted = [...widget.scheduledTrips]
      ..sort((a, b) => a.scheduledDatetime.compareTo(b.scheduledDatetime));
    return sorted.first;
  }

  void _onItemTap(int index) {
    if (index == 1) {
      widget.onSecurityTap?.call();
      return;
    }
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasPendingTrips) ...[
            _SettingsItem(
              icon: Icons.calendar_month_rounded,
              iconBackgroundColor: AppColors.highlight,
              label: 'Viagens Agendadas',
              isExpanded: _expandedIndex == 0,
              isExpandable: true,
              onTap: () => _onItemTap(0),
            ),
            const _Divider(),
            _buildExpandableContent(
              isExpanded: _expandedIndex == 0,
              child: _SingleScheduledTripContent(
                trip: _nextTrip!,
                onDetailsTap: widget.onScheduledTripDetailsTap,
                onViewAllTap: widget.onViewAllScheduledTap,
              ),
            ),
          ],
          _SettingsItem(
            icon: Icons.edit_rounded,
            iconBackgroundColor: AppColors.highlight,
            label: 'Edição de Perfil',
            isExpanded: false,
            isExpandable: false,
            onTap: () => _onItemTap(1),
          ),
          const _Divider(),
          _SettingsItem(
            icon: Icons.history_rounded,
            iconBackgroundColor: AppColors.highlight,
            label: 'Histórico de Corridas',
            isExpanded: _expandedIndex == 2,
            isExpandable: true,
            onTap: () => _onItemTap(2),
          ),
          _buildExpandableContent(
            isExpanded: _expandedIndex == 2,
            child: _TripHistoryContent(
              trips: widget.tripHistory,
              onTap: widget.onHistoryTripTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableContent({
    required bool isExpanded,
    required Widget child,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: isExpanded ? child : const SizedBox.shrink(),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final String label;
  final bool isExpanded;
  final bool isExpandable;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconBackgroundColor,
    required this.label,
    required this.isExpanded,
    required this.isExpandable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpandable && isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
    );
  }
}

class _SingleScheduledTripContent extends StatelessWidget {
  final ScheduledTrip trip;
  final VoidCallback? onDetailsTap;
  final VoidCallback? onViewAllTap;

  const _SingleScheduledTripContent({
    required this.trip,
    this.onDetailsTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) => ScheduledTripWidget(
              trip: trip,
              onDetailsTap: () => TripDetailsSheet.show(context, trip),
              showMapPreview: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewAllTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripHistoryContent extends StatelessWidget {
  final List<MockTripHistory> trips;
  final VoidCallback? onTap;

  const _TripHistoryContent({
    required this.trips,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < trips.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            TripHistoryCard(
              trip: trips[i],
              onTap: onTap,
            ),
          ],
        ],
      ),
    );
  }
}
