import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/price_offer_details.dart';

class AwaitingDriverContent extends StatefulWidget {
  const AwaitingDriverContent({
    super.key,
    required this.details,
    required this.cancelling,
    required this.error,
    required this.onContinue,
    required this.onCancel,
  });

  final PriceOfferDetails details;
  final bool cancelling;
  final String? error;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  State<AwaitingDriverContent> createState() => _AwaitingDriverContentState();
}

class _AwaitingDriverContentState extends State<AwaitingDriverContent>
    with TickerProviderStateMixin {
  late final AnimationController _radar;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _radar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _radar.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      body: Stack(
        children: [
          const Positioned(
            left: -130,
            top: -150,
            child: _AmbientGlow(size: 310),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 190),
                  sliver: SliverList.list(
                    children: [
                      _AnimatedEntrance(
                        animation: _entrance,
                        interval: const Interval(0, .45),
                        child: const _Header(),
                      ),
                      const SizedBox(height: 20),
                      _AnimatedEntrance(
                        animation: _entrance,
                        interval: const Interval(.08, .58),
                        child: _SearchHero(
                          key: const Key('advanced-search-radar'),
                          animation: _radar,
                          driverName: details.driverName,
                          avatarUrl: details.driverAvatarUrl,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _AnimatedEntrance(
                        animation: _entrance,
                        interval: const Interval(.18, .68),
                        child: _DriverSummary(details: details),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedEntrance(
                        animation: _entrance,
                        interval: const Interval(.28, .78),
                        child: _TripSummary(details: details),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedEntrance(
                        animation: _entrance,
                        interval: const Interval(.38, .88),
                        child: const _WhatHappensNext(),
                      ),
                      if (widget.error != null) ...[
                        const SizedBox(height: 14),
                        _ErrorCard(message: widget.error!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomActions(
              cancelling: widget.cancelling,
              onContinue: widget.onContinue,
              onCancel: widget.onCancel,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7E2D8)),
          ),
          child: const Icon(
            Icons.schedule_send_rounded,
            color: Color(0xFF292721),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOLICITAÇÃO ENVIADA',
                style: TextStyle(
                  color: Color(0xFF9A7200),
                  fontSize: 10.5,
                  letterSpacing: 1.45,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Estamos cuidando de tudo',
                style: TextStyle(
                  fontFamily: 'OutfitBlack',
                  fontSize: 21,
                  color: Color(0xFF24221E),
                ),
              ),
            ],
          ),
        ),
        _LiveBadge(),
      ],
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EE),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: .35, end: 1).animate(_pulse),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF20A356),
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 7, height: 7),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'AO VIVO',
            style: TextStyle(
              color: Color(0xFF16733E),
              fontSize: 9.5,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHero extends StatelessWidget {
  const _SearchHero({
    super.key,
    required this.animation,
    required this.driverName,
    required this.avatarUrl,
  });

  final Animation<double> animation;
  final String driverName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171714), Color(0xFF2D2921)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 184,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) => CustomPaint(
                painter: _RadarPainter(progress: animation.value),
                child: Center(child: child),
              ),
              child: _RadarAvatar(name: driverName, avatarUrl: avatarUrl),
            ),
          ),
          Text(
            'A aguardar $driverName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'OutfitBlack',
              fontSize: 24,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_tethering_rounded,
                color: AppColors.highlight,
                size: 17,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'A aguardar resposta em tempo real',
                  style: TextStyle(
                    color: Color(0xFFC9C5BC),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Text(
            'Receberá uma notificação assim que o motorista responder. Pode continuar a usar a aplicação normalmente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9F9B92),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarAvatar extends StatelessWidget {
  const _RadarAvatar({required this.name, required this.avatarUrl});
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final image = avatarUrl == null || avatarUrl!.isEmpty
        ? null
        : NetworkImage(avatarUrl!);
    return Container(
      width: 82,
      height: 82,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.highlight, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.highlight.withValues(alpha: .44),
            blurRadius: 22,
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.highlightSoft,
        backgroundImage: image,
        onBackgroundImageError: image == null ? null : (error, stackTrace) {},
        child: image == null
            ? Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontFamily: 'OutfitBlack',
                  fontSize: 29,
                ),
              )
            : null,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = math.min(size.width, size.height) * .47;
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1;
      final radius = 43 + (maxRadius - 43) * phase;
      final opacity = (1 - phase) * .52;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.highlight.withValues(alpha: opacity),
      );
    }
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          AppColors.highlight.withValues(alpha: 0),
          AppColors.highlight.withValues(alpha: .07),
          AppColors.highlight.withValues(alpha: .44),
          AppColors.highlight.withValues(alpha: 0),
        ],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, sweep);

    final angle = progress * math.pi * 2;
    final dot =
        center + Offset(math.cos(angle), math.sin(angle)) * maxRadius * .82;
    canvas.drawCircle(dot, 3.2, Paint()..color = AppColors.highlight);
    canvas.drawCircle(
      dot,
      8,
      Paint()..color = AppColors.highlight.withValues(alpha: .16),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DriverSummary extends StatelessWidget {
  const _DriverSummary({required this.details});
  final PriceOfferDetails details;

  @override
  Widget build(BuildContext context) {
    final vehicle = details.vehicle;
    final vehicleName = vehicle == null
        ? 'Veículo será confirmado pelo motorista'
        : [
            vehicle.brand,
            vehicle.model,
            if (vehicle.year != null) '${vehicle.year}',
          ].where((item) => item.isNotEmpty).join(' ');
    return _SurfaceCard(
      child: Row(
        children: [
          _SmallAvatar(name: details.driverName, url: details.driverAvatarUrl),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MOTORISTA SOLICITADO',
                  style: TextStyle(
                    color: Color(0xFF99948A),
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details.driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'OutfitBlack',
                    fontSize: 18,
                    color: Color(0xFF25231F),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (details.rating != null) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.highlight,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        details.rating!.toStringAsFixed(1).replaceAll('.', ','),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '  •  ',
                        style: TextStyle(color: Color(0xFFB7B2A8)),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        vehicleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF77736B),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0BD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF8B6800),
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.name, required this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final image = url == null || url!.isEmpty ? null : NetworkImage(url!);
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFFFE3A0),
      backgroundImage: image,
      onBackgroundImageError: image == null ? null : (error, stackTrace) {},
      child: image == null
          ? Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'OutfitBlack',
                fontSize: 20,
                color: Color(0xFF684C00),
              ),
            )
          : null,
    );
  }
}

class _TripSummary extends StatelessWidget {
  const _TripSummary({required this.details});
  final PriceOfferDetails details;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.route_rounded,
            title: 'Resumo da viagem',
          ),
          const SizedBox(height: 17),
          _RouteLine(
            icon: Icons.my_location_rounded,
            color: const Color(0xFF21A45B),
            label: 'PARTIDA',
            address: details.pickupAddress,
            showConnector: true,
          ),
          for (final stop in details.stopAddresses)
            _RouteLine(
              icon: Icons.more_horiz_rounded,
              color: AppColors.highlight,
              label: 'PARADA',
              address: stop,
              showConnector: true,
            ),
          _RouteLine(
            icon: Icons.location_on_rounded,
            color: const Color(0xFFEB594B),
            label: 'DESTINO',
            address: details.dropoffAddress,
            showConnector: false,
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.people_alt_rounded,
                label:
                    '${details.passengerCount} ${details.passengerCount == 1 ? 'passageiro' : 'passageiros'}',
              ),
              if (details.luggageCount > 0)
                _InfoChip(
                  icon: Icons.luggage_rounded,
                  label:
                      '${details.luggageCount} ${details.luggageCount == 1 ? 'bagagem' : 'bagagens'}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
    required this.showConnector,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String address;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25,
            child: Column(
              children: [
                Icon(icon, size: 18, color: color),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE1DDD4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF9B968D),
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: const TextStyle(
                      color: Color(0xFF34312C),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6E685E)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF575249),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatHappensNext extends StatelessWidget {
  const _WhatHappensNext();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'O que acontece agora?',
          ),
          const SizedBox(height: 16),
          const _StatusItem(
            icon: Icons.check_rounded,
            color: Color(0xFF21A45B),
            title: 'Solicitação entregue',
            subtitle: 'O motorista já recebeu os detalhes da viagem.',
            done: true,
          ),
          Container(
            width: 1.5,
            height: 15,
            margin: const EdgeInsets.only(left: 17),
            color: Color(0xFFE1DDD4),
          ),
          const _StatusItem(
            icon: Icons.hourglass_top_rounded,
            color: AppColors.highlight,
            title: 'A aguardar análise',
            subtitle: 'Ele pode aceitar ou enviar uma proposta de valor.',
            done: false,
          ),
          Container(
            width: 1.5,
            height: 15,
            margin: const EdgeInsets.only(left: 17),
            color: Color(0xFFE1DDD4),
          ),
          const _StatusItem(
            icon: Icons.notifications_active_rounded,
            color: Color(0xFF8A857C),
            title: 'Resposta instantânea',
            subtitle: 'Avisamos imediatamente pela app.',
            done: false,
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.done,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF34312C),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF858077),
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0BD),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF806300)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF292621),
            fontFamily: 'OutfitBlack',
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E3D9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBE8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDC6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC84335)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF9C3329), fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.cancelling,
    required this.onContinue,
    required this.onCancel,
  });
  final bool cancelling;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F2).withValues(alpha: .97),
        border: const Border(top: BorderSide(color: Color(0xFFE5E1D8))),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.highlight,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.explore_rounded, size: 19),
              label: const Text(
                'Continuar navegando',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: cancelling ? null : onCancel,
              icon: cancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close_rounded, size: 18),
              label: Text(
                cancelling ? 'Cancelando...' : 'Cancelar solicitação',
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF746E64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({
    required this.animation,
    required this.interval,
    required this.child,
  });
  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: interval);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: curved, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.highlight.withValues(alpha: .18),
              AppColors.highlight.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
