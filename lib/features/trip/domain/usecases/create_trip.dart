import 'package:kz_servicos_app/features/trip/domain/entities/trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';

class CreateTrip {
  CreateTrip(this._repository);

  final TripRepository _repository;

  Future<Trip> call(TripRequest request) => _repository.createTrip(request);
}
