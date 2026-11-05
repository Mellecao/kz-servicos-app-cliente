import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';

import '../../../../core/constants/app_colors.dart';

import '../../domain/entities/price_offer_details.dart';

class PriceOfferContent extends StatelessWidget {
  const PriceOfferContent({
    super.key,
    required this.details,
    required this.offeredPrice,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    this.error,
  });

  final PriceOfferDetails details;
  final double offeredPrice;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final String? error;

  String get _price => formatKz(offeredPrice);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F6F2),
      child: Stack(
        children: [
          const Positioned(
            left: -90,
            top: -110,
            child: _Glow(color: AppColors.highlight, size: 260),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 180),
                  sliver: SliverList.list(
                    children: [
                      const _Entrance(delay: 0, child: _Header()),
                      const SizedBox(height: 22),
                      _Entrance(delay: 80, child: _PriceHero(price: _price)),
                      const SizedBox(height: 16),
                      _Entrance(
                        delay: 140,
                        child: _DriverCard(details: details),
                      ),
                      const SizedBox(height: 16),
                      if (details.driverPhotoUrls.isNotEmpty) ...[
                        _Entrance(
                          delay: 180,
                          child: _PhotoSection(
                            title: 'Conheça o seu motorista',
                            subtitle: 'Fotos verificadas do perfil',
                            urls: details.driverPhotoUrls,
                            icon: Icons.verified_user_rounded,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (details.vehicle != null) ...[
                        _Entrance(
                          delay: 220,
                          child: _VehicleCard(vehicle: details.vehicle!),
                        ),
                        const SizedBox(height: 16),
                        if (details.vehicle!.photoUrls.isNotEmpty) ...[
                          _Entrance(
                            delay: 260,
                            child: _PhotoSection(
                              title: 'Fotos do veículo',
                              subtitle: 'Veja o carro que fará a sua viagem',
                              urls: details.vehicle!.photoUrls,
                              icon: Icons.directions_car_filled_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                      _Entrance(delay: 300, child: _TripCard(details: details)),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorCard(message: error!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActions(
              price: _price,
              busy: busy,
              onAccept: onAccept,
              onReject: onReject,
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
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 21),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROPOSTA RECEBIDA',
                style: TextStyle(
                  color: Color(0xFF9A7200),
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Reveja a sua viagem',
                style: TextStyle(
                  fontFamily: 'OutfitBlack',
                  fontSize: 26,
                  color: Color(0xFF1E1D1B),
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceHero extends StatelessWidget {
  const _PriceHero({required this.price});
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171714), Color(0xFF2C2922)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: AppColors.highlight,
                size: 18,
              ),
              SizedBox(width: 7),
              Text(
                'VALOR PROPOSTO',
                style: TextStyle(
                  color: Color(0xFFCBC7BC),
                  fontSize: 11,
                  letterSpacing: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'OutfitBlack',
                fontSize: 43,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Preço final para a viagem descrita abaixo.',
            style: TextStyle(color: Color(0xFFA9A69E), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.details});
  final PriceOfferDetails details;

  @override
  Widget build(BuildContext context) {
    final rating = details.rating == null
        ? 'Novo'
        : details.rating!.toStringAsFixed(1).replaceAll('.', ',');
    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(name: details.driverName, url: details.driverAvatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SEU MOTORISTA',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.35,
                        color: Color(0xFF918D85),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      details.driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'OutfitBlack',
                        fontSize: 21,
                        color: Color(0xFF24221E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.highlight,
                          size: 18,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        if (details.totalRatings > 0) ...[
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '•  ${details.totalRatings} avaliações',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF817D75),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_rounded,
                color: AppColors.secondary,
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.route_rounded,
                  value: '${details.completedTrips} viagens',
                  label: 'concluídas',
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: _Metric(
                  icon: Icons.shield_rounded,
                  value: 'Verificado',
                  label: 'pela equipa',
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: _Metric(
                  icon: Icons.workspace_premium_rounded,
                  value: 'Parceiro',
                  label: 'aprovado',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final image = url != null && url!.isNotEmpty ? NetworkImage(url!) : null;
    return Container(
      width: 70,
      height: 70,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.highlight, Color(0xFFFF8A00)],
        ),
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFF0EEE7),
        backgroundImage: image,
        onBackgroundImageError: image == null ? null : (error, stackTrace) {},
        child: image == null
            ? Text(
                name.isEmpty ? 'M' : name.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'OutfitBlack',
                  fontSize: 25,
                  color: Color(0xFF645219),
                ),
              )
            : null,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF74601E)),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF8A867E)),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});
  final PriceOfferVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final specifications = [
      if (vehicle.color.isNotEmpty) vehicle.color,
      if (vehicle.year != null) '${vehicle.year}',
      '${vehicle.passengerCapacity} lugares',
    ].join('  •  ');
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.directions_car_filled_rounded,
            title: 'O seu veículo',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.highlight],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: Color(0xFF4C3A00),
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}'.trim(),
                      style: const TextStyle(
                        fontFamily: 'OutfitBlack',
                        fontSize: 20,
                        color: Color(0xFF24221E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specifications,
                      style: const TextStyle(
                        color: Color(0xFF7A766E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF23221F),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 7),
                  ],
                ),
                child: Text(
                  vehicle.licensePlate.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 1.1,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.title,
    required this.subtitle,
    required this.urls,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final List<String> urls;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: _SectionTitle(icon: icon, title: title, subtitle: subtitle),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 134,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: urls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: urls.length == 1
                      ? MediaQuery.sizeOf(context).width - 76
                      : 190,
                  child: Image.network(
                    urls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFF1EFE8),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFFAAA69D),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.details});
  final PriceOfferDetails details;

  @override
  Widget build(BuildContext context) {
    final date = details.scheduledDatetime == null
        ? 'Horário a confirmar'
        : _formatScheduledDate(details.scheduledDatetime!);
    final passengers =
        '${details.passengerCount} ${details.passengerCount == 1 ? 'passageiro' : 'passageiros'}';
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.route_rounded,
            title: 'Detalhes da viagem',
          ),
          const SizedBox(height: 17),
          _InfoBand(
            icon: Icons.calendar_month_rounded,
            title: 'Agendamento',
            value: date,
          ),
          const SizedBox(height: 18),
          _RouteTimeline(
            pickup: details.pickupAddress,
            stops: details.stopAddresses,
            dropoff: details.dropoffAddress,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(icon: Icons.people_alt_rounded, label: passengers),
              if (details.childrenCount > 0)
                _Chip(
                  icon: Icons.child_care_rounded,
                  label:
                      '${details.childrenCount} criança${details.childrenCount == 1 ? '' : 's'}',
                ),
              if (details.luggageCount > 0)
                _Chip(
                  icon: Icons.luggage_rounded,
                  label:
                      '${details.luggageCount} bagage${details.luggageCount == 1 ? 'm' : 'ns'}',
                ),
            ],
          ),
          if (details.observations?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _InfoBand(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Observação',
              value: details.observations!.trim(),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatScheduledDate(DateTime date) {
    const weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${weekdays[date.weekday - 1]}, $day de ${months[date.month - 1]} • $hour:$minute';
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({
    required this.pickup,
    required this.stops,
    required this.dropoff,
  });
  final String pickup;
  final List<String> stops;
  final String dropoff;

  @override
  Widget build(BuildContext context) {
    final points = [
      (
        'PARTIDA',
        pickup,
        const Color(0xFF16A36A),
        Icons.radio_button_checked_rounded,
      ),
      ...stops.indexed.map(
        (entry) => (
          'PARADA ${entry.$1 + 1}',
          entry.$2,
          AppColors.highlight,
          Icons.circle_rounded,
        ),
      ),
      ('DESTINO', dropoff, AppColors.secondary, Icons.location_on_rounded),
    ];
    return Column(
      children: points.indexed.map((entry) {
        final index = entry.$1;
        final point = entry.$2;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    Icon(
                      point.$4,
                      color: point.$3,
                      size: index == points.length - 1 ? 22 : 16,
                    ),
                    if (index < points.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCD8CE),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index < points.length - 1 ? 18 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.$1,
                        style: TextStyle(
                          color: point.$3,
                          fontSize: 9.5,
                          letterSpacing: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        point.$2,
                        style: const TextStyle(
                          color: Color(0xFF33312D),
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoBand extends StatelessWidget {
  const _InfoBand({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3ED),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF776323), size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF97928A),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF383631),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE5E1D8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6F6A61)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF514E48),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.price,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });
  final String price;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

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
        color: const Color(0xFFF7F6F2).withValues(alpha: .96),
        border: const Border(top: BorderSide(color: Color(0xFFE5E1D8))),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              key: const Key('reject-offer'),
              height: 55,
              child: OutlinedButton(
                onPressed: busy ? null : onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5C554C),
                  side: const BorderSide(color: Color(0xFFCCC5B8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const FittedBox(
                  child: Text(
                    'Recusar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              key: const Key('accept-offer'),
              height: 55,
              child: FilledButton(
                onPressed: busy ? null : onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.highlight,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: const Color(0xFFE4D9B6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF57491A),
                        ),
                      )
                    : FittedBox(
                        child: Text(
                          'Confirmar por $price',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0BD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF7B6107)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'OutfitBlack',
                  fontSize: 18,
                  color: Color(0xFF2A2824),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E8980),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 24,
            offset: Offset(0, 10),
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
        color: const Color(0xFFFFE9E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC24136)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF8D2820), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .12),
        ),
      ),
    );
  }
}

class _Entrance extends StatefulWidget {
  const _Entrance({required this.child, required this.delay});
  final Widget child;
  final int delay;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    final total = 520 + widget.delay;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(widget.delay / total, 1, curve: Curves.easeOutCubic),
    );
    _opacity = curve;
    _position = Tween(
      begin: const Offset(0, .06),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _position, child: widget.child),
  );
}
