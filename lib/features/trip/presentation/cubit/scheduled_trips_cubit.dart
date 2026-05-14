import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_state.dart';

class ScheduledTripsCubit extends Cubit<ScheduledTripsState> {
  ScheduledTripsCubit({required TripRepository repository})
      : _repository = repository,
        super(const ScheduledTripsInitial());

  final TripRepository _repository;

  Future<void> load(String clientId) async {
    emit(const ScheduledTripsLoading());
    try {
      final trips = await _repository.getScheduledTrips(clientId);
      emit(ScheduledTripsLoaded(trips));
    } on Exception catch (e) {
      emit(ScheduledTripsError(e.toString()));
    }
  }

  Future<void> refresh(String clientId) async {
    try {
      final trips = await _repository.getScheduledTrips(clientId);
      emit(ScheduledTripsLoaded(trips));
    } on Exception catch (e) {
      emit(ScheduledTripsError(e.toString()));
    }
  }
}
