import 'package:equatable/equatable.dart';

abstract class ServiceRequestState extends Equatable {
  const ServiceRequestState();

  @override
  List<Object?> get props => [];
}

class ServiceRequestInitial extends ServiceRequestState {
  const ServiceRequestInitial();
}

class ServiceRequestSubmitting extends ServiceRequestState {
  const ServiceRequestSubmitting();
}

class ServiceRequestSuccess extends ServiceRequestState {
  const ServiceRequestSuccess();
}

class ServiceRequestError extends ServiceRequestState {
  const ServiceRequestError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
