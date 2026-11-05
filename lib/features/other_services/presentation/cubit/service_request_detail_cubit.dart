import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';

enum RequestDetailStatus { loading, loaded, error }

class ServiceRequestDetailState extends Equatable {
  const ServiceRequestDetailState({
    this.status = RequestDetailStatus.loading,
    this.request,
    this.message,
    this.busy = false,
    this.actionError,
    this.notice,
  });

  final RequestDetailStatus status;
  final ServiceRequest? request;

  /// Erro de carregamento (estado `error`).
  final String? message;

  /// Há uma ação (aceitar/cancelar/abrir chat) a decorrer.
  final bool busy;

  /// Erro da última ação, para mostrar num aviso.
  final String? actionError;

  /// Confirmação da última ação, para mostrar num aviso.
  final String? notice;

  ServiceRequestDetailState copyWith({
    RequestDetailStatus? status,
    ServiceRequest? request,
    String? message,
    bool? busy,
    String? actionError,
    String? notice,
  }) => ServiceRequestDetailState(
    status: status ?? this.status,
    request: request ?? this.request,
    message: message,
    busy: busy ?? this.busy,
    actionError: actionError,
    notice: notice,
  );

  @override
  List<Object?> get props => [status, request, message, busy, actionError, notice];
}

/// Detalhe de um pedido de serviço: dados reais (com prestador e preço final),
/// atualizados em tempo real, mais as ações do cliente (aceitar, cancelar,
/// abrir o chat).
class ServiceRequestDetailCubit extends Cubit<ServiceRequestDetailState> {
  ServiceRequestDetailCubit({
    required ServiceRequestRepository repository,
    required this.requestId,
    ServiceRequest? initial,
    this.refreshInterval = const Duration(seconds: 15),
  }) : _repository = repository,
       super(
         initial == null
             ? const ServiceRequestDetailState()
             : ServiceRequestDetailState(
                 status: RequestDetailStatus.loaded,
                 request: initial,
               ),
       );

  final ServiceRequestRepository _repository;
  final String requestId;

  /// Recarga periódica de segurança (o realtime é a via principal).
  /// `Duration.zero` desativa-a.
  final Duration refreshInterval;

  StreamSubscription<void>? _changes;
  Timer? _timer;

  static const _genericLoadError = 'Não foi possível carregar o pedido.';

  Future<void> load() async {
    try {
      final request = await _repository.fetchServiceRequestById(requestId);
      if (isClosed) return;
      emit(
        state.copyWith(status: RequestDetailStatus.loaded, request: request),
      );
    } catch (_) {
      if (isClosed) return;
      if (state.request == null) {
        emit(
          state.copyWith(
            status: RequestDetailStatus.error,
            message: _genericLoadError,
          ),
        );
      }
    }
    _startWatching();
  }

  void _startWatching() {
    if (_changes == null) {
      try {
        _changes = _repository.requestChanges(requestId).listen((_) => _refresh());
      } catch (_) {
        _changes = null;
      }
    }
    if (_timer == null && refreshInterval > Duration.zero) {
      _timer = Timer.periodic(refreshInterval, (_) => _refresh());
    }
  }

  /// Recarrega sem piscar o ecrã; se falhar, mantém o que já está visível.
  Future<void> _refresh() async {
    if (isClosed) return;
    try {
      final request = await _repository.fetchServiceRequestById(requestId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RequestDetailStatus.loaded,
          request: request,
          busy: state.busy,
          actionError: state.actionError,
          notice: state.notice,
        ),
      );
      if (request.status.isFinal) _timer?.cancel();
    } catch (_) {}
  }

  Future<bool> accept() async {
    final request = state.request;
    if (request == null || !request.status.canAccept) return false;
    return _act(
      () => _repository.acceptProvider(requestId),
      success: 'Prestador aceite. A aguardar a confirmação do prestador.',
      fallback: 'Não foi possível aceitar o prestador. Tente novamente.',
    );
  }

  Future<bool> cancel() async {
    final request = state.request;
    if (request == null || !request.status.canCancel) return false;
    return _act(
      () => _repository.cancelServiceRequest(requestId),
      success: 'Pedido cancelado.',
      fallback: 'Não foi possível cancelar o pedido. Tente novamente.',
    );
  }

  Future<bool> _act(
    Future<void> Function() action, {
    required String success,
    required String fallback,
  }) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true, request: state.request));
    String? error;
    try {
      await action();
    } on ServiceRequestActionException catch (e) {
      error = e.message;
    } catch (_) {
      error = fallback;
    }
    await _reloadQuietly();
    if (isClosed) return error == null;
    emit(
      state.copyWith(
        busy: false,
        actionError: error,
        notice: error == null ? success : null,
      ),
    );
    return error == null;
  }

  Future<void> _reloadQuietly() async {
    try {
      final request = await _repository.fetchServiceRequestById(requestId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RequestDetailStatus.loaded,
          request: request,
          busy: state.busy,
        ),
      );
    } catch (_) {}
  }

  /// Id da sala de chat com o prestador, ou `null` (sem prestador / falha).
  Future<String?> openChat() async {
    final provider = state.request?.provider;
    if (provider == null || state.busy) return null;
    emit(state.copyWith(busy: true, request: state.request));
    try {
      final room = await _repository.ensureChatRoom(
        serviceRequestId: requestId,
        providerUserId: provider.userId,
      );
      if (!isClosed) emit(state.copyWith(busy: false, request: state.request));
      return room;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            busy: false,
            request: state.request,
            actionError: 'Não foi possível abrir a conversa. Tente novamente.',
          ),
        );
      }
      return null;
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _changes?.cancel();
    return super.close();
  }
}
