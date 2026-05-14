import 'package:equatable/equatable.dart';

abstract class TripCreationState extends Equatable {
  const TripCreationState();

  @override
  List<Object?> get props => [];
}

class TripCreationInitial extends TripCreationState {
  const TripCreationInitial();
}

class TripCreationLoading extends TripCreationState {
  const TripCreationLoading();
}

class TripCreationSuccess extends TripCreationState {
  const TripCreationSuccess({required this.tripId});

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

class TripCreationError extends TripCreationState {
  const TripCreationError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
