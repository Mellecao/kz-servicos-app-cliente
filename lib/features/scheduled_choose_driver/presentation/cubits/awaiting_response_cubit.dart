import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/scheduled_direct_request_repository.dart';
import '../../domain/entities/scheduled_direct_request.dart';
import '../../domain/entities/price_offer_details.dart';

class AwaitingResponseState {
  final ScheduledDirectStatus status;
  final String driverName;
  final String? driverAvatarUrl;
  final double? offeredPrice;
  final bool cancelling;
  final String? error;
  final PriceOfferDetails? details;

  const AwaitingResponseState({
    required this.status,
    required this.driverName,
    required this.driverAvatarUrl,
    required this.offeredPrice,
    required this.cancelling,
    required this.error,
    this.details,
  });

  AwaitingResponseState copyWith({
    ScheduledDirectStatus? status,
    String? driverName,
    String? driverAvatarUrl,
    double? offeredPrice,
    bool? cancelling,
    String? error,
    bool clearError = false,
    PriceOfferDetails? details,
  }) {
    return AwaitingResponseState(
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      driverAvatarUrl: driverAvatarUrl ?? this.driverAvatarUrl,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      cancelling: cancelling ?? this.cancelling,
      error: clearError ? null : (error ?? this.error),
      details: details ?? this.details,
    );
  }
}

class AwaitingResponseCubit extends Cubit<AwaitingResponseState> {
  AwaitingResponseCubit({
    required this.tripId,
    required ScheduledDirectRequestRepository repo,
  }) : _repo = repo,
       super(
         const AwaitingResponseState(
           status: ScheduledDirectStatus.awaitingDriver,
           driverName: '',
           driverAvatarUrl: null,
           offeredPrice: null,
           cancelling: false,
           error: null,
           details: null,
         ),
       );

  final String tripId;
  final ScheduledDirectRequestRepository _repo;
  RealtimeChannel? _channel;

  Future<void> start() async {
    await _refetch();
    _channel = Supabase.instance.client
        .channel('client-scheduled-direct-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (_) => _refetch(),
        )
        .subscribe();
  }

  Future<void> _refetch() async {
    final clientId = Supabase.instance.client.auth.currentUser?.id;
    if (clientId == null) return;
    final row = await _repo.fetchActiveRequest(clientId);
    if (row == null) return;

    final providerRaw = row['driver_profiles'];
    final provider = providerRaw is Map
        ? providerRaw['provider_profiles']
        : null;
    final userRaw = provider is Map ? provider['users'] : null;
    final candidates = (row['trip_driver_candidates'] as List?) ?? const [];
    final candidateStatus = candidates.isNotEmpty
        ? (candidates.first['status'] as String? ?? 'pending')
        : 'pending';
    final offeredPrice = candidates.isNotEmpty
        ? (candidates.first['offered_price'] as num?)?.toDouble()
        : null;

    emit(
      state.copyWith(
        status: scheduledDirectStatusFrom(
          tripStatus: row['status'] as String,
          candidateStatus: candidateStatus,
        ),
        driverName:
            (userRaw is Map ? userRaw['full_name'] as String? : null) ??
            state.driverName,
        driverAvatarUrl: (userRaw is Map
            ? userRaw['avatar_url'] as String?
            : null),
        offeredPrice: offeredPrice,
        details: PriceOfferDetails.fromMap(row),
        clearError: true,
      ),
    );
  }

  Future<void> cancel(String reason) async {
    if (state.cancelling || state.status == ScheduledDirectStatus.cancelled) {
      return;
    }
    emit(state.copyWith(cancelling: true, clearError: true));
    try {
      await _repo.cancel(tripId, reason);
      emit(
        state.copyWith(
          status: ScheduledDirectStatus.cancelled,
          cancelling: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(cancelling: false, error: e.toString()));
    }
  }

  @override
  Future<void> close() async {
    if (_channel != null) {
      await Supabase.instance.client.removeChannel(_channel!);
    }
    return super.close();
  }
}
