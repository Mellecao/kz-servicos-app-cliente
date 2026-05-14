import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';

abstract class ScheduledTripsState extends Equatable {
  const ScheduledTripsState();

  @override
  List<Object?> get props => [];
}

class ScheduledTripsInitial extends ScheduledTripsState {
  const ScheduledTripsInitial();
}

class ScheduledTripsLoading extends ScheduledTripsState {
  const ScheduledTripsLoading();
}

class ScheduledTripsLoaded extends ScheduledTripsState {
  const ScheduledTripsLoaded(this.trips);

  final List<ScheduledTrip> trips;

  @override
  List<Object?> get props => [trips];
}

class ScheduledTripsError extends ScheduledTripsState {
  const ScheduledTripsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
