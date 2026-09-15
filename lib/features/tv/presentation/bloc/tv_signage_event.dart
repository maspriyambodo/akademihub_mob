import 'package:equatable/equatable.dart';

abstract class TvSignageEvent extends Equatable {
  const TvSignageEvent();

  @override
  List<Object?> get props => [];
}

class TvSignageStarted extends TvSignageEvent {
  const TvSignageStarted();
}

class TvSignageRefreshRequested extends TvSignageEvent {
  const TvSignageRefreshRequested();
}

class TvSignageNextSlideTicked extends TvSignageEvent {
  final int direction;
  const TvSignageNextSlideTicked({this.direction = 1});
  @override
  List<Object?> get props => [direction];
}

class TvSignageCacheExpired extends TvSignageEvent {
  const TvSignageCacheExpired();
}

class TvSignageUnpairConfirmed extends TvSignageEvent {
  const TvSignageUnpairConfirmed();
}
