import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../../domain/repositories/tv_repository.dart';
import 'tv_signage_event.dart';
import 'tv_signage_state.dart';

class TvSignageBloc extends Bloc<TvSignageEvent, TvSignageState> {
  final TvRepository _repository;
  final DateTime Function() _now;
  Timer? _slideTimer;
  Timer? _syncTimer;
  Timer? _expiryTimer;
  Timer? _idleTimer;
  bool _fetching = false;
  bool _unpairing = false;
  bool _isPaused = false;

  TvSignageBloc({required TvRepository repository, DateTime Function()? now})
    : _repository = repository,
      _now = now ?? DateTime.now,
      super(const TvSignageInitial()) {
    on<TvSignageStarted>(_onStarted);
    on<TvSignageRefreshRequested>(_onRefreshRequested);
    on<TvSignageNextSlideTicked>(_onNextSlideTicked);
    on<TvSignageUnpairConfirmed>(_onUnpairConfirmed);
    on<TvSignageCacheExpired>((event, emit) => _expireCache(emit));
  }

  bool _expired(DateTime syncedAt) {
    final age = _now().toUtc().difference(syncedAt);
    return age.isNegative || age >= const Duration(hours: 24);
  }

  void _expireCache(Emitter<TvSignageState> emit) {
    if (state is TvSignageReady && _expired((state as TvSignageReady).lastSyncedAt)) {
      _slideTimer?.cancel();
      emit(const TvSignageOffline('Cache kedaluwarsa. Hubungkan internet untuk sinkronisasi.'));
    }
  }

  void _scheduleExpiry(DateTime syncedAt) {
    _expiryTimer?.cancel();
    final remaining = syncedAt.add(const Duration(hours: 24)).difference(_now().toUtc());
    _expiryTimer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (!isClosed) add(const TvSignageCacheExpired());
    });
  }

  static int calculateTotalSlides(TvSnapshot snapshot) {
    int count = 0;
    if (snapshot.schedule.isNotEmpty) count++;
    count += snapshot.announcements.length;
    if (snapshot.calendar.isNotEmpty) count++;
    return count > 0 ? count : 1;
  }

  Future<void> _onStarted(
    TvSignageStarted event,
    Emitter<TvSignageState> emit,
  ) async {
    // 1. Cache-first strategy
    final cachedResult = await _repository.readCachedSnapshot();
    if (emit.isDone || _unpairing) return;
    if (cachedResult.isSuccess && cachedResult.requireData != null && !_expired(cachedResult.requireData!.generatedAt)) {
      final cached = cachedResult.requireData!;
      emit(
        TvSignageReady(
          snapshot: cached,
          isOffline: true,
          lastSyncedAt: cached.generatedAt,
        ),
      );
      _scheduleSlideTimer(cached.settings.slideDurationSeconds);
      _scheduleExpiry(cached.generatedAt);
    } else {
      emit(const TvSignageLoading());
    }

    // 2. Fetch fresh network snapshot
    await _fetchSnapshot(emit);
  }

  Future<void> _onRefreshRequested(
    TvSignageRefreshRequested event,
    Emitter<TvSignageState> emit,
  ) async {
    await _fetchSnapshot(emit);
  }

  Future<void> _fetchSnapshot(Emitter<TvSignageState> emit) async {
    _expireCache(emit);
    if (_fetching || _unpairing) return;
    _fetching = true;
    try {
    final currentEtag = state is TvSignageReady
        ? (state as TvSignageReady).etag
        : null;
    final result = await _repository.getSnapshot(etag: currentEtag);
    if (emit.isDone || _unpairing) return;

    if (result.isSuccess) {
      final fetch = result.requireData;
      if (fetch is TvSnapshotModified) {
        final newSnapshot = fetch.snapshot;
        emit(
          TvSignageReady(
            snapshot: newSnapshot,
            currentSlideIndex: 0,
            isOffline: false,
            lastSyncedAt: _now().toUtc(),
            etag: fetch.etag,
          ),
        );
        _scheduleSlideTimer(newSnapshot.settings.slideDurationSeconds);
        _scheduleSyncTimer(newSnapshot.refreshAfter);
        _scheduleExpiry((state as TvSignageReady).lastSyncedAt);
      } else if (fetch is TvSnapshotNotModified) {
        if (state is TvSignageReady) {
          final readyState = state as TvSignageReady;
          emit(
            readyState.copyWith(
              isOffline: false,
              lastSyncedAt: _now().toUtc(),
            ),
          );
          _scheduleSyncTimer(readyState.snapshot.refreshAfter);
          _scheduleExpiry((state as TvSignageReady).lastSyncedAt);
        } else {
          _scheduleSyncTimer(30);
        }
      }
    } else {
      final failure = result.requireFailure;
      if (failure is AuthFailure) {
        _cancelAllTimers();
        emit(const TvSignageAuthExpired());
        return;
      }

      if (state is TvSignageReady) {
        final readyState = state as TvSignageReady;
        emit(readyState.copyWith(isOffline: true));
        // Retry sync after 30 seconds
        _scheduleSyncTimer(30);
      } else {
        emit(TvSignageOffline(failure.message));
        _scheduleSyncTimer(30);
      }
    }
    } finally {
      _fetching = false;
    }
  }

  void _onNextSlideTicked(
    TvSignageNextSlideTicked event,
    Emitter<TvSignageState> emit,
  ) {
    _expireCache(emit);
    if (state is! TvSignageReady) return;
    final readyState = state as TvSignageReady;
    final total = calculateTotalSlides(readyState.snapshot);
    final nextIndex = (readyState.currentSlideIndex + event.direction) % total;

    emit(readyState.copyWith(currentSlideIndex: nextIndex));
    _scheduleSlideTimer(readyState.snapshot.settings.slideDurationSeconds);
  }

  Future<void> _onUnpairConfirmed(
    TvSignageUnpairConfirmed event,
    Emitter<TvSignageState> emit,
  ) async {
    _unpairing = true;
    _cancelAllTimers();
    await _repository.unpair();
    emit(const TvSignageAuthExpired());
  }

  void _scheduleSlideTimer(int durationSeconds) {
    _slideTimer?.cancel();
    if (_isPaused || isClosed || (_idleTimer?.isActive ?? false)) return;
    final seconds = durationSeconds.clamp(10, 120);
    _slideTimer = Timer(Duration(seconds: seconds), () {
      if (!isClosed) add(const TvSignageNextSlideTicked());
    });
  }

  void _scheduleSyncTimer(int intervalSeconds) {
    _syncTimer?.cancel();
    if (_isPaused || isClosed) return;
    final seconds = intervalSeconds.clamp(15, 3600);
    _syncTimer = Timer(Duration(seconds: seconds), () {
      if (!isClosed) add(const TvSignageRefreshRequested());
    });
  }

  void pause() {
    _isPaused = true;
    _cancelAllTimers();
  }

  void interact() {
    _slideTimer?.cancel();
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 30), () {
      if (state is TvSignageReady) _scheduleSlideTimer((state as TvSignageReady).snapshot.settings.slideDurationSeconds);
    });
  }

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    add(const TvSignageCacheExpired());
    add(const TvSignageRefreshRequested());
    if (state is TvSignageReady) {
      final ready = state as TvSignageReady;
      _scheduleSlideTimer(ready.snapshot.settings.slideDurationSeconds);
      _scheduleSyncTimer(ready.snapshot.refreshAfter);
      _scheduleExpiry(ready.lastSyncedAt);
    }
  }

  void _cancelAllTimers() {
    _slideTimer?.cancel();
    _slideTimer = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _expiryTimer?.cancel();
    _idleTimer?.cancel();
  }

  @override
  Future<void> close() {
    _cancelAllTimers();
    return super.close();
  }
}
