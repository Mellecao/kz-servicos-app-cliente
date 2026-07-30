import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/available_drivers_repository.dart';
import '../../data/repositories/scheduled_direct_request_repository.dart';
import '../../domain/entities/available_driver.dart';

sealed class DriverSelectionState {
  const DriverSelectionState();
}

class DriverSelectionInitial extends DriverSelectionState {
  const DriverSelectionInitial();
}

class DriverSelectionLoading extends DriverSelectionState {
  const DriverSelectionLoading();
}

class DriverSelectionLoaded extends DriverSelectionState {
  final List<AvailableDriver> drivers;
  final String? sendingDriverId;
  const DriverSelectionLoaded({required this.drivers, this.sendingDriverId});

  DriverSelectionLoaded copyWith({
    List<AvailableDriver>? drivers,
    String? sendingDriverId,
    bool clearSending = false,
  }) {
    return DriverSelectionLoaded(
      drivers: drivers ?? this.drivers,
      sendingDriverId: clearSending ? null : (sendingDriverId ?? this.sendingDriverId),
    );
  }
}

class DriverSelectionError extends DriverSelectionState {
  final String message;
  const DriverSelectionError(this.message);
}

class DriverSelectionRequestSent extends DriverSelectionState {
  final String tripId;
  const DriverSelectionRequestSent(this.tripId);
}

class DriverSelectionCubit extends Cubit<DriverSelectionState> {
  DriverSelectionCubit({
    required AvailableDriversRepository driversRepo,
    required ScheduledDirectRequestRepository requestRepo,
    required this.pickupAddressId,
    required this.dropoffAddressId,
    required this.serviceCategoryId,
    required this.passengerCount,
    required this.scheduledDatetime,
    this.observation,
  })  : _driversRepo = driversRepo,
        _requestRepo = requestRepo,
        super(const DriverSelectionInitial());

  final AvailableDriversRepository _driversRepo;
  final ScheduledDirectRequestRepository _requestRepo;
  final String pickupAddressId;
  final String dropoffAddressId;
  final String serviceCategoryId;
  final int passengerCount;
  final DateTime scheduledDatetime;
  final String? observation;

  Future<void> load() async {
    emit(const DriverSelectionLoading());
    try {
      final drivers = await _driversRepo.fetchApproved();
      emit(DriverSelectionLoaded(drivers: drivers));
    } catch (e) {
      emit(DriverSelectionError(e.toString()));
    }
  }

  Future<void> request(String driverProfileId) async {
    final s = state;
    if (s is! DriverSelectionLoaded) return;
    emit(s.copyWith(sendingDriverId: driverProfileId));
    try {
      final tripId = await _requestRepo.sendRequest(
        driverProfileId: driverProfileId,
        pickupAddressId: pickupAddressId,
        dropoffAddressId: dropoffAddressId,
        serviceCategoryId: serviceCategoryId,
        passengerCount: passengerCount,
        scheduledDatetime: scheduledDatetime,
        observation: observation,
      );
      emit(DriverSelectionRequestSent(tripId));
    } catch (e) {
      emit(DriverSelectionError(e.toString()));
      emit(s.copyWith(clearSending: true));
    }
  }
}
