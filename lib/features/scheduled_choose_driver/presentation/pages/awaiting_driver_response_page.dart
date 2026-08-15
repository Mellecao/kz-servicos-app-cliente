import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/scheduled_direct_request.dart';
import '../../domain/navigation/scheduled_direct_routes.dart';
import '../../../trip/presentation/widgets/cancel_trip_dialog.dart';
import '../cubits/awaiting_response_cubit.dart';
import '../widgets/awaiting_driver_content.dart';

class AwaitingDriverResponsePage extends StatelessWidget {
  const AwaitingDriverResponsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AwaitingResponseCubit, AwaitingResponseState>(
        listener: (context, state) {
          if (state.status == ScheduledDirectStatus.priceOffered) {
            final cubit = context.read<AwaitingResponseCubit>();
            context.go('/scheduled-choose-driver/price-review/${cubit.tripId}');
          } else if (state.status == ScheduledDirectStatus.rejected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.driverName} não pôde aceitar. Escolha outro.',
                ),
              ),
            );
            context.go('/');
          } else if (state.status == ScheduledDirectStatus.confirmed) {
            final cubit = context.read<AwaitingResponseCubit>();
            context.go(ScheduledDirectRoutes.activeTrip(cubit.tripId));
          } else if (state.status == ScheduledDirectStatus.cancelled) {
            context.go('/');
          }
        },
        builder: (context, state) {
          if (state.driverName.isEmpty || state.details == null) {
            return const ColoredBox(
              color: Color(0xFFF7F6F2),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return AwaitingDriverContent(
            details: state.details!,
            cancelling: state.cancelling,
            error: state.error,
            onContinue: () => context.go('/'),
            onCancel: () async {
              final reason = await showDialog<String>(
                context: context,
                builder: (_) => const CancelTripDialog(),
              );
              if (reason == null || !context.mounted) return;
              await context.read<AwaitingResponseCubit>().cancel(reason);
            },
          );
        },
      ),
    );
  }
}
