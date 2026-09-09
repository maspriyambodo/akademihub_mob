import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../../domain/repositories/tv_repository.dart';
import 'tv_signage_event.dart';
import 'tv_signage_state.dart';

class TvSignageBloc extends Bloc<TvSignageEvent, TvSignageState> {
  final TvRepository _repository;
  Timer? _slideTimer;
  Timer? _syncTimer;
  bool _isPaused = false;

  TvSignageBloc({required TvRepository repository})
    : _repository = repository,
      super(const TvSignageInitial()) {
    on<TvSignageStarted>(_onStarted);
    on<TvSignageRefreshRequested>(_onRefreshRequested);
    on<TvSignageNextSlideTicked>(_onNextSlideTicked);
    on<TvSignageUnpairConfirmed>(_onUnpairConfirmed);
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
    if (cachedResult.isSuccess && cachedResult.requireData != null) {
      final cached = cachedResult.requireData!;
      emit(
        TvSignageReady(
          snapshot: cached,
          isOffline: true,
          lastSyncedAt: cached.generatedAt,
        ),
      );
      _scheduleSlideTimer(cached.settings.slideDurationSeconds);
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
    final currentEtag = state is TvSignageReady
        ? (state as TvSignageReady).etag
        : null;
    final result = await _repository.getSnapshot(etag: currentEtag);

    if (result.isSuccess) {
      final fetch = result.requireData;
      if (fetch is TvSnapshotModified) {
        final newSnapshot = fetch.snapshot;
        emit(
          TvSignageReady(
            snapshot: newSnapshot,
            currentSlideIndex: 0,
            isOffline: false,
            lastSyncedAt: DateTime.now().toUtc(),
            etag: fetch.etag,
          ),
        );
        _scheduleSlideTimer(newSnapshot.settings.slideDurationSeconds);
        _scheduleSyncTimer(newSnapshot.refreshAfter);
      } else if (fetch is TvSnapshotNotModified) {
        if (state is TvSignageReady) {
          final readyState = state as TvSignageReady;
          emit(
            readyState.copyWith(
              isOffline: false,
              lastSyncedAt: DateTime.now().toUtc(),
            ),
          );
          _scheduleSyncTimer(readyState.snapshot.refreshAfter);
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
  }

  void _onNextSlideTicked(
    TvSignageNextSlideTicked event,
    Emitter<TvSignageState> emit,
  ) {
    if (state is! TvSignageReady) return;
    final readyState = state as TvSignageReady;
    final total = calculateTotalSlides(readyState.snapshot);
    final nextIndex = (readyState.currentSlideIndex + 1) % total;

    emit(readyState.copyWith(currentSlideIndex: nextIndex));
    _scheduleSlideTimer(readyState.snapshot.settings.slideDurationSeconds);
  }

  Future<void> _onUnpairConfirmed(
    TvSignageUnpairConfirmed event,
    Emitter<TvSignageState> emit,
  ) async {
    _cancelAllTimers();
    await _repository.unpair();
    emit(const TvSignageAuthExpired());
  }

  void _scheduleSlideTimer(int durationSeconds) {
    _slideTimer?.cancel();
    if (_isPaused || isClosed) return;
    final seconds = durationSeconds.clamp(5, 60);
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

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    if (state is TvSignageReady) {
      final ready = state as TvSignageReady;
      _scheduleSlideTimer(ready.snapshot.settings.slideDurationSeconds);
      _scheduleSyncTimer(ready.snapshot.refreshAfter);
    } else {
      add(const TvSignageRefreshRequested());
    }
  }

  void _cancelAllTimers() {
    _slideTimer?.cancel();
    _slideTimer = null;
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  Future<void> close() {
    _cancelAllTimers();
    return super.close();
  }
}
