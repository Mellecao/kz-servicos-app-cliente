import 'package:equatable/equatable.dart';

sealed class FlashCreationState extends Equatable {
  const FlashCreationState();
  @override
  List<Object?> get props => [];
}

class FlashCreationInitial extends FlashCreationState {
  const FlashCreationInitial();
}

class FlashCreationLoading extends FlashCreationState {
  const FlashCreationLoading();
}

class FlashCreationSuccess extends FlashCreationState {
  final String tripId;
  const FlashCreationSuccess(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class FlashCreationError extends FlashCreationState {
  final String message;
  const FlashCreationError(this.message);
  @override
  List<Object?> get props => [message];
}
