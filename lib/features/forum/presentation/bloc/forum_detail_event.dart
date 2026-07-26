part of 'forum_detail_bloc.dart';

abstract class ForumDetailEvent extends Equatable {
  const ForumDetailEvent();

  @override
  List<Object?> get props => [];
}

class ForumDetailLoadRequested extends ForumDetailEvent {
  final int id;
  const ForumDetailLoadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class ForumDetailRefreshRequested extends ForumDetailEvent {
  const ForumDetailRefreshRequested();
}
