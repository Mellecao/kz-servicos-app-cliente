import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import 'package:kz_servicos_app/features/profile/data/models/mock_trip_history.dart';

class TripHistoryCard extends StatelessWidget {
  final MockTripHistory trip;
  final VoidCallback? onTap;

  const TripHistoryCard({super.key, required this.trip, this.onTap});

  static const _monthAbbreviations = [
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

  String _formatDate(DateTime date) {
    final day = date.day;
    final month = _monthAbbreviations[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month • $hour:$minute';
  }

  String _formatPrice(double price) {
    return formatKz(price);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sheetSurface,
          borderRadius: BorderRadius.circular(20),
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
            _MiniMapPreview(),
            _TripDetails(
              origin: trip.origin,
              destination: trip.destination,
              formattedDate: _formatDate(trip.completedAt),
              formattedPrice: _formatPrice(trip.price),
              rating: trip.rating,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMapPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: CustomPaint(painter: const _RoutePainter()),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFFF5F5F5);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Route line
    final routePaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startX = size.width * 0.15;
    final endX = size.width * 0.85;
    final centerY = size.height * 0.5;
    final controlY1 = size.height * 0.2;
    final controlY2 = size.height * 0.8;

    final path = Path()
      ..moveTo(startX, centerY)
      ..cubicTo(
        size.width * 0.4,
        controlY1,
        size.width * 0.6,
        controlY2,
        endX,
        centerY,
      );

    canvas.drawPath(path, routePaint);

    // Origin dot (blue)
    final originPaint = Paint()..color = AppColors.secondary;
    canvas.drawCircle(Offset(startX, centerY), 5, originPaint);

    // Destination dot (yellow)
    final destPaint = Paint()..color = AppColors.highlight;
    canvas.drawCircle(Offset(endX, centerY), 5, destPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TripDetails extends StatelessWidget {
  final String origin;
  final String destination;
  final String formattedDate;
  final String formattedPrice;
  final double rating;

  const _TripDetails({
    required this.origin,
    required this.destination,
    required this.formattedDate,
    required this.formattedPrice,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RouteRow(origin: origin, destination: destination),
          const SizedBox(height: 10),
          _InfoRow(
            formattedDate: formattedDate,
            formattedPrice: formattedPrice,
            rating: rating,
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String origin;
  final String destination;

  const _RouteRow({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            origin,
            style: const TextStyle(
              fontFamily: 'QuasimodoSemiBold',
              fontSize: 13,
              color: AppColors.sheetTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 14, color: Color(0xFF9E9E9E)),
        ),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.highlight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(
                    fontFamily: 'QuasimodoSemiBold',
                    fontSize: 13,
                    color: AppColors.sheetTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String formattedDate;
  final String formattedPrice;
  final double rating;

  const _InfoRow({
    required this.formattedDate,
    required this.formattedPrice,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 13,
          color: Color(0xFF9E9E9E),
        ),
        const SizedBox(width: 4),
        Text(
          formattedDate,
          style: const TextStyle(
            fontFamily: 'QuasimodoSemiBold',
            fontSize: 12,
            color: Color(0xFF9E9E9E),
          ),
        ),
        const Spacer(),
        Text(
          formattedPrice,
          style: const TextStyle(
            fontFamily: 'OutfitBlack',
            fontSize: 14,
            color: AppColors.sheetTextPrimary,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.star, size: 14, color: AppColors.highlight),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontFamily: 'QuasimodoSemiBold',
            fontSize: 12,
            color: AppColors.sheetTextPrimary,
          ),
        ),
      ],
    );
  }
}
