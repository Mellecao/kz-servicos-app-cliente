import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/flash_proposal_model.dart';
import '../../domain/repositories/flash_trip_repository.dart';
import 'flash_searching_state.dart';

class FlashSearchingCubit extends Cubit<FlashSearchingState> {
  final FlashTripRepository repository;
  final String tripId;
  StreamSubscription? _proposalsSub;
  StreamSubscription? _statusSub;

  FlashSearchingCubit({required this.repository, required this.tripId})
      : super(const FlashSearchingIdle());

  void start() {
    _proposalsSub = repository.watchProposals(tripId).listen((rows) {
      final proposals = rows
          .map((r) => FlashProposalModel.fromJson(r).toEntity())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(FlashSearchingProposals(proposals));
    });
    _statusSub = repository.watchTripStatus(tripId).listen((row) {
      final status = row['status'] as String?;
      switch (status) {
        case 'awaiting_driver_confirmation':
          emit(const FlashSearchingAwaitingDriver('Motorista'));
          break;
        case 'scheduled':
        case 'started':
          emit(const FlashSearchingReadyToStart());
          break;
        case 'cancelled':
          emit(const FlashSearchingCancelled());
          break;
      }
    });
  }

  Future<void> acceptProposal(String candidateId) async {
    try {
      await repository.acceptProposal(candidateId);
    } catch (e) {
      emit(FlashSearchingError(e.toString()));
    }
  }

  Future<void> cancelTrip(String reason) async {
    try {
      await repository.cancelFlashTrip(tripId, reason);
    } catch (e) {
      emit(FlashSearchingError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _proposalsSub?.cancel();
    await _statusSub?.cancel();
    return super.close();
  }
}
