import 'package:equatable/equatable.dart';

class Trip extends Equatable {
  const Trip({
    required this.id,
    required this.clientId,
    required this.status,
    required this.scheduledDatetime,
    required this.passengerCount,
    this.observations,
    this.createdAt,
  });

  final String id;
  final String clientId;
  final String status;
  final DateTime scheduledDatetime;
  final int passengerCount;
  final String? observations;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, clientId, status];
}
