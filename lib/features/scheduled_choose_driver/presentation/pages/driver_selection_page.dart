import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/driver_selection_cubit.dart';
import '../widgets/driver_card.dart';

class DriverSelectionPage extends StatelessWidget {
  const DriverSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolha seu motorista')),
      body: BlocConsumer<DriverSelectionCubit, DriverSelectionState>(
        listener: (context, state) {
          if (state is DriverSelectionRequestSent) {
            context.go('/scheduled-choose-driver/awaiting/${state.tripId}');
          } else if (state is DriverSelectionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is DriverSelectionInitial) {
            context.read<DriverSelectionCubit>().load();
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DriverSelectionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DriverSelectionLoaded) {
            if (state.drivers.isEmpty) {
              return const Center(child: Text('Nenhum motorista aprovado disponível.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.drivers.length,
              itemBuilder: (context, index) {
                final d = state.drivers[index];
                return DriverCard(
                  driver: d,
                  isLoading: state.sendingDriverId == d.driverProfileId,
                  onRequest: (id) => context.read<DriverSelectionCubit>().request(id),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
