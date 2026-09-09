import 'package:equatable/equatable.dart';

abstract class TvAuthEvent extends Equatable {
  const TvAuthEvent();

  @override
  List<Object?> get props => [];
}

class TvAuthStarted extends TvAuthEvent {
  const TvAuthStarted();
}

class TvPairingRequested extends TvAuthEvent {
  const TvPairingRequested();
}

class TvPairingPollTicked extends TvAuthEvent {
  const TvPairingPollTicked();
}

class TvPairingRetryRequested extends TvAuthEvent {
  const TvPairingRetryRequested();
}

class TvUnpairRequested extends TvAuthEvent {
  const TvUnpairRequested();
}
