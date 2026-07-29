import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/scheduled_direct_request.dart';
import '../cubits/awaiting_response_cubit.dart';

class AwaitingDriverResponsePage extends StatelessWidget {
  const AwaitingDriverResponsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aguardando resposta')),
      body: BlocConsumer<AwaitingResponseCubit, AwaitingResponseState>(
        listener: (context, state) {
          if (state.status == ScheduledDirectStatus.priceOffered) {
            final cubit = context.read<AwaitingResponseCubit>();
            context.go('/scheduled-choose-driver/price-review/${cubit.tripId}');
          } else if (state.status == ScheduledDirectStatus.rejected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${state.driverName} não pôde aceitar. Escolha outro.')),
            );
            context.go('/');
          } else if (state.status == ScheduledDirectStatus.confirmed) {
            final cubit = context.read<AwaitingResponseCubit>();
            context.go('/active-trip?tripId=${cubit.tripId}');
          }
        },
        builder: (context, state) {
          if (state.driverName.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      state.driverAvatarUrl != null ? NetworkImage(state.driverAvatarUrl!) : null,
                  child: state.driverAvatarUrl == null
                      ? Text(state.driverName.isNotEmpty
                          ? state.driverName[0].toUpperCase()
                          : '?')
                      : null,
                ),
                const SizedBox(height: 16),
                Text('Solicitação enviada a',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(state.driverName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                  ),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => context.go('/'),
                      child: const Text('Continuar navegando'),
                    ),
                    OutlinedButton(
                      onPressed: state.cancelling
                          ? null
                          : () => context
                              .read<AwaitingResponseCubit>()
                              .cancel('cancelado pelo cliente'),
                      child: state.cancelling
                          ? const Text('Cancelando...')
                          : const Text('Cancelar solicitação'),
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
