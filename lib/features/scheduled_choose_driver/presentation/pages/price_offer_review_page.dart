import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/scheduled_direct_request_repository.dart';
import '../cubits/awaiting_response_cubit.dart';

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
      if (mounted) context.go('/active-trip?tripId=${widget.tripId}');
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
      appBar: AppBar(title: const Text('Proposta de preço')),
      body: BlocBuilder<AwaitingResponseCubit, AwaitingResponseState>(
        builder: (context, state) {
          if (state.offeredPrice == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.driverName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text('Propôs o valor de', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  'R\$ ${state.offeredPrice!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 32),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _busy ? null : _reject,
                      child: const Text('Recusar preço'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _busy ? null : _accept,
                      child: const Text('Confirmar corrida'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
