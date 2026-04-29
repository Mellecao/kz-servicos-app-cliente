import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/driver_candidate.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';

/// A trip that is awaiting client confirmation and the list of drivers
/// who have applied to it (and been accepted by the system).
class TripWithCandidates extends Equatable {
  const TripWithCandidates({required this.trip, required this.candidates});

  final ScheduledTrip trip;
  final List<DriverCandidate> candidates;

  @override
  List<Object?> get props => [trip, candidates];
}
