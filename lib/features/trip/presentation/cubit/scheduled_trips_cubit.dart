import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduledTripsCubit extends Cubit<ScheduledTripsState> {
  ScheduledTripsCubit({required TripRepository repository})
      : _repository = repository,
        super(const ScheduledTripsInitial());

  final TripRepository _repository;
  String? _clientId;
  RealtimeChannel? _channel;

  Future<void> load(String clientId) async {
    _clientId = clientId;
    emit(const ScheduledTripsLoading());
    try {
      final trips = await _repository.getScheduledTrips(clientId);
      emit(ScheduledTripsLoaded(trips));
    } on Exception catch (e) {
      emit(ScheduledTripsError(e.toString()));
    }
    _subscribeRealtime(clientId);
  }

  void _subscribeRealtime(String clientId) {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('scheduled-trips-$clientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: clientId,
          ),
          callback: (_) => _refresh(),
        )
        .subscribe();
  }

  Future<void> _refresh() async {
    if (_clientId == null) return;
    try {
      final trips = await _repository.getScheduledTrips(_clientId!);
      if (!isClosed) emit(ScheduledTripsLoaded(trips));
    } on Exception catch (_) {}
  }

  Future<void> refresh(String clientId) async {
    _clientId = clientId;
    try {
      final trips = await _repository.getScheduledTrips(clientId);
      emit(ScheduledTripsLoaded(trips));
    } on Exception catch (e) {
      emit(ScheduledTripsError(e.toString()));
    }
  }

  Future<void> cancel(String tripId) async {
    if (_clientId == null) return;
    try {
      await _repository.cancelTrip(tripId);
      final trips = await _repository.getScheduledTrips(_clientId!);
      emit(ScheduledTripsLoaded(trips));
    } on Exception catch (_) {}
  }

  @override
  Future<void> close() async {
    await _channel?.unsubscribe();
    return super.close();
  }
}
