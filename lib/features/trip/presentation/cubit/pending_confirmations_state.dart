import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_with_candidates.dart';

abstract class PendingConfirmationsState extends Equatable {
  const PendingConfirmationsState();

  @override
  List<Object?> get props => [];
}

class PendingConfirmationsInitial extends PendingConfirmationsState {
  const PendingConfirmationsInitial();
}

class PendingConfirmationsLoading extends PendingConfirmationsState {
  const PendingConfirmationsLoading();
}

class PendingConfirmationsLoaded extends PendingConfirmationsState {
  const PendingConfirmationsLoaded(this.items);

  final List<TripWithCandidates> items;

  @override
  List<Object?> get props => [items];
}

class PendingConfirmationsError extends PendingConfirmationsState {
  const PendingConfirmationsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
