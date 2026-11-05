import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/cubit/trips_enabled_cubit.dart';

/// Escolhe a primeira tela do Cliente pelo interruptor `trips_enabled`:
/// `true` ⇒ a home de viagens original; `false` (ou falha) ⇒ "Buscar
/// prestadores". Enquanto lê, mostra um indicador (nunca a tela errada).
class HomeGate extends StatefulWidget {
  const HomeGate({
    super.key,
    required this.tripBuilder,
    required this.searchBuilder,
  });

  final WidgetBuilder tripBuilder;
  final WidgetBuilder searchBuilder;

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  @override
  void initState() {
    super.initState();
    context.read<TripsEnabledCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripsEnabledCubit, TripsEnabledState>(
      builder: (context, state) => switch (state) {
        TripsEnabledState.loading => const Scaffold(
          backgroundColor: AppColors.brandDark,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.highlight),
          ),
        ),
        TripsEnabledState.enabled => widget.tripBuilder(context),
        TripsEnabledState.disabled => widget.searchBuilder(context),
      },
    );
  }
}
