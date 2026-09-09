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
  const TvSignageNextSlideTicked();
}

class TvSignageUnpairConfirmed extends TvSignageEvent {
  const TvSignageUnpairConfirmed();
}
