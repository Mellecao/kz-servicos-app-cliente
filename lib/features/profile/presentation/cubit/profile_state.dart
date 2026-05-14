import 'package:equatable/equatable.dart';

class ProfileStats extends Equatable {
  const ProfileStats({
    required this.completedTrips,
    required this.requestedServices,
    required this.unreadMessages,
  });

  final int completedTrips;
  final int requestedServices;
  final int unreadMessages;

  @override
  List<Object?> get props =>
      [completedTrips, requestedServices, unreadMessages];
}

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.stats);

  final ProfileStats stats;

  @override
  List<Object?> get props => [stats];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
