part of 'forum_bloc.dart';

abstract class ForumState extends Equatable {
  const ForumState();

  @override
  List<Object?> get props => [];
}

class ForumInitial extends ForumState {}

class ForumLoading extends ForumState {}

class ForumLoaded extends ForumState {
  final List<ForumEntity> items;
  final String search;

  /// null = semua tipe.
  final int? tipe;

  final bool hasMore;
  final bool isLoadingMore;
  final int? total;

  /// Id user yang sedang login (untuk cek kepemilikan post).
  final int? userId;

  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  /// `sekolah_id` yang disimpulkan; null berarti belum bisa membuat post.
  final int? sekolahId;

  /// Penanda revisi data. WAJIB ada: `ForumEntity.props` hanya berisi `id`
  /// (sesuai pola entity proyek), sehingga daftar hasil edit dianggap sama
  /// dengan daftar sebelumnya oleh Equatable dan `emit` akan dilewati Bloc.
  /// Counter ini membuat setiap pemuatan ulang benar-benar terkirim ke UI.
  final int revisi;

  const ForumLoaded({
    required this.items,
    required this.search,
    required this.tipe,
    required this.hasMore,
    required this.isLoadingMore,
    required this.revisi,
    this.total,
    this.userId,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
    this.sekolahId,
  });

  /// FAB hanya tampil bila user punya permission `forum.create`.
  bool get bolehBuat => canCreate;

  /// Aksi ubah hanya untuk post milik sendiri + permission `forum.update`.
  bool bolehUbah(ForumEntity post) => canUpdate && post.milikUser(userId);

  /// Aksi hapus hanya untuk post milik sendiri + permission `forum.delete`.
  bool bolehHapus(ForumEntity post) => canDelete && post.milikUser(userId);

  ForumEntity? itemById(int id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    items,
    search,
    tipe,
    hasMore,
    isLoadingMore,
    revisi,
    total,
    userId,
    canCreate,
    canUpdate,
    canDelete,
    sekolahId,
  ];
}

class ForumError extends ForumState {
  final String message;
  const ForumError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk SnackBar setelah aksi berhasil.
class ForumActionSuccess extends ForumState {
  final String message;
  const ForumActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk SnackBar setelah aksi gagal.
class ForumActionFailure extends ForumState {
  final String message;
  const ForumActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
