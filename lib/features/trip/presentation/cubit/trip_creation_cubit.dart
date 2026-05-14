import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';
import 'package:kz_servicos_app/features/trip/domain/usecases/create_trip.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/trip_creation_state.dart';

class TripCreationCubit extends Cubit<TripCreationState> {
  TripCreationCubit({required CreateTrip createTrip})
    : _createTrip = createTrip,
      super(const TripCreationInitial());

  final CreateTrip _createTrip;

  Future<void> submit(TripRequest request) async {
    emit(const TripCreationLoading());
    try {
      final trip = await _createTrip(request);
      emit(TripCreationSuccess(tripId: trip.id));
    } catch (e) {
      debugPrint('[KZ] TripCreation error: $e');
      emit(TripCreationError(
        message: 'Não foi possível criar a viagem. Tente novamente.',
      ));
    }
  }

  void reset() => emit(const TripCreationInitial());
}
