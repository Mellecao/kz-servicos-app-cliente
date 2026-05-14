import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';

abstract class ServiceRequestsListState extends Equatable {
  const ServiceRequestsListState();

  @override
  List<Object?> get props => [];
}

class ServiceRequestsListInitial extends ServiceRequestsListState {
  const ServiceRequestsListInitial();
}

class ServiceRequestsListLoading extends ServiceRequestsListState {
  const ServiceRequestsListLoading();
}

class ServiceRequestsListLoaded extends ServiceRequestsListState {
  const ServiceRequestsListLoaded(this.requests);

  final List<ServiceRequest> requests;

  @override
  List<Object?> get props => [requests];
}

class ServiceRequestsListError extends ServiceRequestsListState {
  const ServiceRequestsListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
