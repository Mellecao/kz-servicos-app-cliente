import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/flash_creation_cubit.dart';
import '../cubit/flash_creation_state.dart';

class FlashDetailsPage extends StatefulWidget {
  final String pickupAddressId;
  final String dropoffAddressId;
  final String serviceCategoryId;
  const FlashDetailsPage({
    super.key,
    required this.pickupAddressId,
    required this.dropoffAddressId,
    required this.serviceCategoryId,
  });

  @override
  State<FlashDetailsPage> createState() => _FlashDetailsPageState();
}

class _FlashDetailsPageState extends State<FlashDetailsPage> {
  int passengers = 1;
  int children = 0;
  int luggage = 0;
  final obsController = TextEditingController();

  @override
  void dispose() {
    obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FlashCreationCubit, FlashCreationState>(
      listener: (context, state) {
        if (state is FlashCreationSuccess) {
          context.go('/flash/searching/${state.tripId}');
        } else if (state is FlashCreationError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalhes da corrida Flash')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _stepperRow('Passageiros', passengers,
                (v) => setState(() => passengers = v),
                min: 1),
            _stepperRow(
                'Crianças', children, (v) => setState(() => children = v)),
            _stepperRow(
                'Bagagens', luggage, (v) => setState(() => luggage = v)),
            const SizedBox(height: 12),
            TextField(
              controller: obsController,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Observações (opcional)'),
            ),
            const SizedBox(height: 24),
            BlocBuilder<FlashCreationCubit, FlashCreationState>(
              builder: (ctx, state) => ElevatedButton(
                onPressed: state is FlashCreationLoading
                    ? null
                    : () {
                        ctx.read<FlashCreationCubit>().submit(
                              pickupAddressId: widget.pickupAddressId,
                              dropoffAddressId: widget.dropoffAddressId,
                              serviceCategoryId: widget.serviceCategoryId,
                              passengerCount: passengers,
                              childrenCount: children,
                              luggageCount: luggage,
                              observations: obsController.text,
                            );
                      },
                child: state is FlashCreationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Solicitar Flash'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperRow(String label, int value, ValueChanged<int> onChanged,
      {int min = 0}) {
    return Row(children: [
      Expanded(child: Text(label)),
      IconButton(
        icon: const Icon(Icons.remove),
        onPressed: value > min ? () => onChanged(value - 1) : null,
      ),
      Text('$value'),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => onChanged(value + 1),
      ),
    ]);
  }
}
