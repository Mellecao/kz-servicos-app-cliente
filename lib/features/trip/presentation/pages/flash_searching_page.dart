import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/flash_proposal.dart';
import '../cubit/flash_searching_cubit.dart';
import '../cubit/flash_searching_state.dart';
import '../widgets/flash_driver_profile_modal.dart';
import '../widgets/flash_proposal_card.dart';

class FlashSearchingPage extends StatefulWidget {
  final String tripId;
  const FlashSearchingPage({super.key, required this.tripId});

  @override
  State<FlashSearchingPage> createState() => _FlashSearchingPageState();
}

class _FlashSearchingPageState extends State<FlashSearchingPage> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        context.read<FlashSearchingCubit>().start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlashSearchingCubit, FlashSearchingState>(
      listener: (ctx, state) {
        if (state is FlashSearchingReadyToStart) {
          ctx.go('/trip?activeTripId=${widget.tripId}');
        } else if (state is FlashSearchingCancelled) {
          ctx.go('/home');
        } else if (state is FlashSearchingError) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (ctx, state) => Scaffold(
        appBar: AppBar(
          title: const Text('À procura de motoristas'),
          actions: [
            TextButton(
              onPressed: () => ctx.read<FlashSearchingCubit>().cancelTrip(
                'Cliente cancelou',
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        body: switch (state) {
          FlashSearchingProposals(:final proposals) when proposals.isNotEmpty =>
            ListView(
              children: proposals
                  .map(
                    (p) => FlashProposalCard(
                      proposal: p,
                      onTap: () => _openProfile(ctx, p),
                    ),
                  )
                  .toList(),
            ),
          FlashSearchingAwaitingDriver(:final driverName) => Center(
            child: Text('A aguardar que $driverName confirme...'),
          ),
          _ => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('À procura de motoristas...'),
              ],
            ),
          ),
        },
      ),
    );
  }

  Future<void> _openProfile(BuildContext ctx, FlashProposal proposal) async {
    final cubit = ctx.read<FlashSearchingCubit>();
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: FlashDriverProfileModal(
          proposal: proposal,
          repository: cubit.repository,
          onAccept: () => cubit.acceptProposal(proposal.candidateId),
        ),
      ),
    );
  }
}
