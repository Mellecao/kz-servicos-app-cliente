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
              SnackBar(
                content: Text('${state.driverName} não pôde aceitar. Escolha outro.'),
              ),
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
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundImage: state.driverAvatarUrl != null
                                  ? NetworkImage(state.driverAvatarUrl!)
                                  : null,
                              child: state.driverAvatarUrl == null
                                  ? Text(
                                      state.driverName.isNotEmpty
                                          ? state.driverName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Solicitação enviada a',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.driverName,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            const SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aguardando resposta do motorista.\nVocê pode continuar navegando enquanto isso.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            if (state.error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                state.error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Continuar navegando'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: state.cancelling
                          ? null
                          : () => context
                              .read<AwaitingResponseCubit>()
                              .cancel('cancelado pelo cliente'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          state.cancelling
                              ? 'Cancelando...'
                              : 'Cancelar solicitação',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
