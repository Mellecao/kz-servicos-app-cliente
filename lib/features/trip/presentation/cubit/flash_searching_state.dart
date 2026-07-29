import 'package:equatable/equatable.dart';
import '../../domain/entities/flash_proposal.dart';

sealed class FlashSearchingState extends Equatable {
  const FlashSearchingState();
  @override
  List<Object?> get props => [];
}

class FlashSearchingIdle extends FlashSearchingState {
  const FlashSearchingIdle();
}

class FlashSearchingProposals extends FlashSearchingState {
  final List<FlashProposal> proposals;
  const FlashSearchingProposals(this.proposals);
  @override
  List<Object?> get props => [proposals];
}

class FlashSearchingAwaitingDriver extends FlashSearchingState {
  final String driverName;
  const FlashSearchingAwaitingDriver(this.driverName);
  @override
  List<Object?> get props => [driverName];
}

class FlashSearchingReadyToStart extends FlashSearchingState {
  const FlashSearchingReadyToStart();
}

class FlashSearchingCancelled extends FlashSearchingState {
  const FlashSearchingCancelled();
}

class FlashSearchingError extends FlashSearchingState {
  final String message;
  const FlashSearchingError(this.message);
  @override
  List<Object?> get props => [message];
}
