import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/pending_confirmations_state.dart';

class PendingConfirmationsCubit extends Cubit<PendingConfirmationsState> {
  PendingConfirmationsCubit({required TripRepository repository})
      : _repository = repository,
        super(const PendingConfirmationsInitial());

  final TripRepository _repository;

  Future<void> load(String clientId) async {
    emit(const PendingConfirmationsLoading());
    try {
      final items =
          await _repository.getTripsAwaitingClientConfirmation(clientId);
      emit(PendingConfirmationsLoaded(items));
    } on Exception catch (e) {
      emit(PendingConfirmationsError(e.toString()));
    }
  }

  Future<void> acceptCandidate({
    required String tripId,
    required String driverProfileId,
    String? vehicleId,
  }) async {
    await _repository.acceptDriverCandidate(
      tripId: tripId,
      driverProfileId: driverProfileId,
      vehicleId: vehicleId,
    );
  }

  void clear() {
    emit(const PendingConfirmationsInitial());
  }
}
