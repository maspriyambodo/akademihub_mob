part of 'forum_bloc.dart';

abstract class ForumEvent extends Equatable {
  const ForumEvent();

  @override
  List<Object?> get props => [];
}

/// Muat pertama kali. Konteks user dikirim dari halaman (dibaca dari AuthBloc).
class ForumLoadRequested extends ForumEvent {
  /// `UserEntity.id` — dipakai untuk mengecek kepemilikan post
  /// (`trx_forum.created_by`) dan sebagai `created_by` saat membuat post.
  final int? userId;

  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  /// Petunjuk `sekolah_id` bila tersedia di profil user. Bila null, bloc
  /// menyimpulkannya dari post yang dimuat.
  final int? sekolahIdHint;

  const ForumLoadRequested({
    this.userId,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
    this.sekolahIdHint,
  });

  @override
  List<Object?> get props => [
    userId,
    canCreate,
    canUpdate,
    canDelete,
    sekolahIdHint,
  ];
}

class ForumRefreshRequested extends ForumEvent {
  const ForumRefreshRequested();
}

class ForumSearchChanged extends ForumEvent {
  final String search;
  const ForumSearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}

/// [tipe] null = semua tipe. Nilai valid: 1 diskusi, 2 pertanyaan,
/// 3 pengumuman.
class ForumTipeFilterChanged extends ForumEvent {
  final int? tipe;
  const ForumTipeFilterChanged(this.tipe);

  @override
  List<Object?> get props => [tipe];
}

class ForumLoadMoreRequested extends ForumEvent {
  const ForumLoadMoreRequested();
}

class ForumCreateRequested extends ForumEvent {
  final String judul;
  final String konten;
  final int tipe;
  final bool isAnonymous;

  const ForumCreateRequested({
    required this.judul,
    required this.konten,
    this.tipe = 1,
    this.isAnonymous = false,
  });

  @override
  List<Object?> get props => [judul, konten, tipe, isAnonymous];
}

class ForumUpdateRequested extends ForumEvent {
  final int id;
  final String judul;
  final String konten;
  final int tipe;
  final bool isAnonymous;

  const ForumUpdateRequested({
    required this.id,
    required this.judul,
    required this.konten,
    this.tipe = 1,
    this.isAnonymous = false,
  });

  @override
  List<Object?> get props => [id, judul, konten, tipe, isAnonymous];
}

class ForumDeleteRequested extends ForumEvent {
  final int id;
  const ForumDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}
