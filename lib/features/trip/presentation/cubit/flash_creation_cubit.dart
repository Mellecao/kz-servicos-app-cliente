import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/flash_trip_repository.dart';
import 'flash_creation_state.dart';

class FlashCreationCubit extends Cubit<FlashCreationState> {
  final FlashTripRepository repository;
  FlashCreationCubit({required this.repository})
      : super(const FlashCreationInitial());

  Future<void> submit({
    required String pickupAddressId,
    required String dropoffAddressId,
    required String serviceCategoryId,
    required int passengerCount,
    required int childrenCount,
    required int luggageCount,
    required String observations,
  }) async {
    emit(const FlashCreationLoading());
    try {
      final id = await repository.createFlashTrip(
        pickupAddressId: pickupAddressId,
        dropoffAddressId: dropoffAddressId,
        serviceCategoryId: serviceCategoryId,
        passengerCount: passengerCount,
        childrenCount: childrenCount,
        luggageCount: luggageCount,
        observations: observations,
      );
      emit(FlashCreationSuccess(id));
    } catch (e) {
      emit(FlashCreationError(e.toString()));
    }
  }
}
