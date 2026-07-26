part of 'forum_detail_bloc.dart';

abstract class ForumDetailState extends Equatable {
  const ForumDetailState();

  @override
  List<Object?> get props => [];
}

class ForumDetailInitial extends ForumDetailState {}

class ForumDetailLoading extends ForumDetailState {}

class ForumDetailLoaded extends ForumDetailState {
  final ForumEntity post;
  const ForumDetailLoaded(this.post);

  @override
  List<Object?> get props => [post, post.updatedAt, post.viewCount];
}

class ForumDetailError extends ForumDetailState {
  final String message;
  const ForumDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
