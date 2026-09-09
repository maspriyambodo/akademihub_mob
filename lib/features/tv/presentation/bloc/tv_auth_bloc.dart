import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tv_pairing_session.dart';
import '../../domain/repositories/tv_repository.dart';
import 'tv_auth_event.dart';
import 'tv_auth_state.dart';

class TvAuthBloc extends Bloc<TvAuthEvent, TvAuthState> {
  final TvRepository _repository;
  Timer? _pollTimer;
  int _consecutiveFailures = 0;
  bool _isPaused = false;

  static const List<int> _backoffSchedule = [5, 10, 20, 30];

  TvAuthBloc({required TvRepository repository})
      : _repository = repository,
        super(const TvAuthInitial()) {
    on<TvAuthStarted>(_onStarted);
    on<TvPairingRequested>(_onPairingRequested);
    on<TvPairingPollTicked>(_onPollTicked);
    on<TvPairingRetryRequested>(_onRetryRequested);
    on<TvUnpairRequested>(_onUnpairRequested);
  }

  Future<void> _onStarted(
    TvAuthStarted event,
    Emitter<TvAuthState> emit,
  ) async {
    emit(const TvAuthChecking());
    final hasToken = await _repository.hasDeviceToken();
    if (hasToken) {
      emit(const TvAuthPaired());
    } else {
      add(const TvPairingRequested());
    }
  }

  Future<void> _onPairingRequested(
    TvPairingRequested event,
    Emitter<TvAuthState> emit,
  ) async {
    _cancelTimer();
    _consecutiveFailures = 0;
    emit(const TvPairingLoading());

    final result = await _repository.createPairingSession();
    if (result.isSuccess) {
      final session = result.requireData;
      emit(TvPairingPending(session: session));
      _schedulePoll(session.pollInterval);
    } else {
      emit(TvAuthFailure(message: result.requireFailure.message));
    }
  }

  Future<void> _onPollTicked(
    TvPairingPollTicked event,
    Emitter<TvAuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TvPairingPending) {
      _cancelTimer();
      return;
    }

    if (currentState.session.isExpired) {
      _cancelTimer();
      emit(TvPairingExpired(session: currentState.session));
      return;
    }

    final result = await _repository.getPairingStatus(currentState.session.sessionId);
    if (result.isSuccess) {
      _consecutiveFailures = 0;
      final status = result.requireData;

      switch (status.state) {
        case TvPairingState.approved:
          _cancelTimer();
          emit(TvAuthPaired(
            deviceId: status.deviceId,
            deviceMode: status.deviceMode,
          ));
          break;

        case TvPairingState.pending:
          if (status.expiresAt != null &&
              DateTime.now().toUtc().isAfter(status.expiresAt!)) {
            _cancelTimer();
            emit(TvPairingExpired(session: currentState.session));
          } else {
            emit(TvPairingPending(
              session: currentState.session,
              attempt: currentState.attempt + 1,
            ));
            _schedulePoll(currentState.session.pollInterval);
          }
          break;

        case TvPairingState.denied:
          _cancelTimer();
          emit(const TvPairingDenied());
          break;

        case TvPairingState.expired:
          _cancelTimer();
          emit(TvPairingExpired(session: currentState.session));
          break;
      }
    } else {
      final failure = result.requireFailure;

      if (failure is RateLimitFailure) {
        final waitSeconds = max(failure.retryAfterSeconds, 3);
        _schedulePoll(Duration(seconds: waitSeconds));
        return;
      }

      _consecutiveFailures++;
      final backoffIndex = min(
        _consecutiveFailures - 1,
        _backoffSchedule.length - 1,
      );
      final baseBackoff = _backoffSchedule[backoffIndex];
      // Random jitter 0-2 seconds
      final jitter = Random().nextInt(3);
      final waitSeconds = baseBackoff + jitter;

      _schedulePoll(Duration(seconds: waitSeconds));
    }
  }

  Future<void> _onRetryRequested(
    TvPairingRetryRequested event,
    Emitter<TvAuthState> emit,
  ) async {
    add(const TvPairingRequested());
  }

  Future<void> _onUnpairRequested(
    TvUnpairRequested event,
    Emitter<TvAuthState> emit,
  ) async {
    _cancelTimer();
    await _repository.unpair();
    add(const TvPairingRequested());
  }

  void pausePolling() {
    _isPaused = true;
    _cancelTimer();
  }

  void resumePolling() {
    if (!_isPaused) return;
    _isPaused = false;
    if (state is TvPairingPending) {
      final session = (state as TvPairingPending).session;
      if (session.isExpired) {
        add(const TvPairingPollTicked());
      } else {
        _schedulePoll(session.pollInterval);
      }
    }
  }

  void _schedulePoll(Duration interval) {
    _cancelTimer();
    if (_isPaused || isClosed) return;

    final duration = interval.inSeconds < 3 ? const Duration(seconds: 3) : interval;
    _pollTimer = Timer(duration, () {
      if (!isClosed) {
        add(const TvPairingPollTicked());
      }
    });
  }

  void _cancelTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
