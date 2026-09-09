import 'package:equatable/equatable.dart';
import '../../domain/entities/tv_snapshot.dart';

abstract class TvSignageState extends Equatable {
  const TvSignageState();

  @override
  List<Object?> get props => [];
}

class TvSignageInitial extends TvSignageState {
  const TvSignageInitial();
}

class TvSignageLoading extends TvSignageState {
  const TvSignageLoading();
}

class TvSignageReady extends TvSignageState {
  final TvSnapshot snapshot;
  final int currentSlideIndex;
  final bool isOffline;
  final DateTime lastSyncedAt;
  final String? etag;

  const TvSignageReady({
    required this.snapshot,
    this.currentSlideIndex = 0,
    this.isOffline = false,
    required this.lastSyncedAt,
    this.etag,
  });

  TvSignageReady copyWith({
    TvSnapshot? snapshot,
    int? currentSlideIndex,
    bool? isOffline,
    DateTime? lastSyncedAt,
    String? etag,
  }) {
    return TvSignageReady(
      snapshot: snapshot ?? this.snapshot,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      isOffline: isOffline ?? this.isOffline,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      etag: etag ?? this.etag,
    );
  }

  @override
  List<Object?> get props => [
        snapshot,
        currentSlideIndex,
        isOffline,
        lastSyncedAt,
        etag,
      ];
}

class TvSignageOffline extends TvSignageState {
  final String message;

  const TvSignageOffline([this.message = 'Tidak ada koneksi dan belum ada cache layar']);

  @override
  List<Object?> get props => [message];
}

class TvSignageAuthExpired extends TvSignageState {
  const TvSignageAuthExpired();
}
