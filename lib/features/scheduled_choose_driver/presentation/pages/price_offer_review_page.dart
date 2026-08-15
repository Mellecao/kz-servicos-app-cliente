import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/scheduled_direct_request_repository.dart';
import '../../domain/navigation/scheduled_direct_routes.dart';
import '../cubits/awaiting_response_cubit.dart';
import '../widgets/price_offer_content.dart';

class PriceOfferReviewPage extends StatefulWidget {
  const PriceOfferReviewPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<PriceOfferReviewPage> createState() => _PriceOfferReviewPageState();
}

class _PriceOfferReviewPageState extends State<PriceOfferReviewPage> {
  bool _busy = false;
  String? _error;
  final _repo = ScheduledDirectRequestRepository();

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.acceptPrice(widget.tripId);
      if (mounted) context.go(ScheduledDirectRoutes.activeTrip(widget.tripId));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _reject() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.rejectPrice(widget.tripId);
      if (mounted) context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AwaitingResponseCubit, AwaitingResponseState>(
        builder: (context, state) {
          if (state.offeredPrice == null || state.details == null) {
            return const ColoredBox(
              color: Color(0xFFF7F6F2),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return PriceOfferContent(
            details: state.details!,
            offeredPrice: state.offeredPrice!,
            busy: _busy,
            error: _error,
            onAccept: _accept,
            onReject: _reject,
          );
        },
      ),
    );
  }
}
