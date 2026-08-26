import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/forum_entity.dart';
import '../../domain/usecases/create_forum_usecase.dart';
import '../../domain/usecases/delete_forum_usecase.dart';
import '../../domain/usecases/get_forum_usecase.dart';
import '../../domain/usecases/update_forum_usecase.dart';

part 'forum_event.dart';
part 'forum_state.dart';

/// Bloc daftar forum + aksi tulis (buat/ubah/hapus).
///
/// Forum backend datar (tanpa balasan), jadi bloc ini hanya mengelola daftar
/// post beserta paginasi cursor, pencarian, dan filter tipe.
class ForumBloc extends Bloc<ForumEvent, ForumState> {
  final GetForumListUseCase getForumList;
  final CreateForumUseCase createForum;
  final UpdateForumUseCase updateForum;
  final DeleteForumUseCase deleteForum;

  static const int _perPage = 20;

  // ── Cache internal ─────────────────────────────────────────────────────────
  List<ForumEntity> _items = const [];
  String _search = '';
  int? _tipe;
  String? _nextCursor;
  bool _hasMore = false;
  int? _total;
  bool _sedangMuatLagi = false;

  /// Naik setiap kali isi `_items` berubah — dipakai `ForumLoaded.revisi`.
  int _revisi = 0;

  int? _userId;
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;

  /// `sekolah_id` tidak pernah dikirim backend pada payload user/tenant, jadi
  /// nilainya disimpulkan dari post yang sudah ada. Bisa di-seed dari profil
  /// user lewat [ForumLoadRequested.sekolahIdHint].
  int? _sekolahId;

  ForumBloc({
    required this.getForumList,
    required this.createForum,
    required this.updateForum,
    required this.deleteForum,
  }) : super(ForumInitial()) {
    on<ForumLoadRequested>(_onLoad);
    on<ForumRefreshRequested>(_onRefresh);
    on<ForumSearchChanged>(_onSearchChanged);
    on<ForumTipeFilterChanged>(_onTipeChanged);
    on<ForumLoadMoreRequested>(_onLoadMore);
    on<ForumCreateRequested>(_onCreate);
    on<ForumUpdateRequested>(_onUpdate);
    on<ForumDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    ForumLoadRequested event,
    Emitter<ForumState> emit,
  ) async {
    _userId = event.userId;
    _canCreate = event.canCreate;
    _canUpdate = event.canUpdate;
    _canDelete = event.canDelete;
    _sekolahId ??= event.sekolahIdHint;
    emit(ForumLoading());
    await _ambilHalamanPertama(emit);
  }

  Future<void> _onRefresh(
    ForumRefreshRequested event,
    Emitter<ForumState> emit,
  ) async {
    await _ambilHalamanPertama(emit);
  }

  Future<void> _onSearchChanged(
    ForumSearchChanged event,
    Emitter<ForumState> emit,
  ) async {
    final baru = event.search.trim();
    if (baru == _search) return;
    _search = baru;
    emit(ForumLoading());
    await _ambilHalamanPertama(emit);
  }

  Future<void> _onTipeChanged(
    ForumTipeFilterChanged event,
    Emitter<ForumState> emit,
  ) async {
    if (event.tipe == _tipe) return;
    _tipe = event.tipe;
    emit(ForumLoading());
    await _ambilHalamanPertama(emit);
  }

  Future<void> _ambilHalamanPertama(Emitter<ForumState> emit) async {
    final result = await getForumList(
      search: _search.isEmpty ? null : _search,
      tipe: _tipe,
      perPage: _perPage,
    );

    if (result.isFailure) {
      emit(ForumError(result.requireFailure.message));
      return;
    }

    final page = result.requireData;
    _items = page.items;
    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
    _total = page.total;
    _sedangMuatLagi = false;
    _revisi++;
    _serapSekolahId();
    emit(_buildLoaded());
  }

  Future<void> _onLoadMore(
    ForumLoadMoreRequested event,
    Emitter<ForumState> emit,
  ) async {
    if (_sedangMuatLagi || !_hasMore || _nextCursor == null) return;

    _sedangMuatLagi = true;
    emit(_buildLoaded());

    final result = await getForumList(
      search: _search.isEmpty ? null : _search,
      tipe: _tipe,
      cursor: _nextCursor,
      perPage: _perPage,
    );

    _sedangMuatLagi = false;

    if (result.isFailure) {
      // Gagal memuat halaman berikutnya tidak boleh menghapus daftar
      // yang sudah tampil — cukup beri tahu lewat SnackBar.
      emit(ForumActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }

    final page = result.requireData;
    final idTerlihat = _items.map((e) => e.id).toSet();
    _items = [..._items, ...page.items.where((e) => idTerlihat.add(e.id))];
    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
    _total = page.total ?? _total;
    _revisi++;
    _serapSekolahId();
    emit(_buildLoaded());
  }

  Future<void> _onCreate(
    ForumCreateRequested event,
    Emitter<ForumState> emit,
  ) async {
    if (!_canCreate) {
      emit(const ForumActionFailure('Anda tidak memiliki izin membuat topik'));
      emit(_buildLoaded());
      return;
    }
    final userId = _userId;
    final sekolahId = _sekolahId;

    if (userId == null) {
      emit(const ForumActionFailure('Data pengguna tidak tersedia'));
      emit(_buildLoaded());
      return;
    }
    if (sekolahId == null) {
      emit(
        const ForumActionFailure(
          'Identitas sekolah belum diketahui. Muat ulang daftar forum '
          'lebih dulu, lalu coba lagi.',
        ),
      );
      emit(_buildLoaded());
      return;
    }

    final result = await createForum(
      sekolahId: sekolahId,
      createdBy: userId,
      judul: event.judul,
      konten: event.konten,
      tipe: event.tipe,
      isAnonymous: event.isAnonymous,
    );

    if (result.isFailure) {
      emit(ForumActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }

    emit(const ForumActionSuccess('Topik berhasil dibuat'));
    // Ambil ulang dari server supaya relasi (penulis/kelas/mapel) ikut terisi.
    await _ambilHalamanPertama(emit);
  }

  Future<void> _onUpdate(
    ForumUpdateRequested event,
    Emitter<ForumState> emit,
  ) async {
    if (!_canUpdate) {
      emit(const ForumActionFailure('Anda tidak memiliki izin mengubah topik'));
      emit(_buildLoaded());
      return;
    }
    final result = await updateForum(
      id: event.id,
      judul: event.judul,
      konten: event.konten,
      tipe: event.tipe,
      isAnonymous: event.isAnonymous,
    );

    if (result.isFailure) {
      emit(ForumActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }

    emit(const ForumActionSuccess('Topik berhasil diperbarui'));
    await _ambilHalamanPertama(emit);
  }

  Future<void> _onDelete(
    ForumDeleteRequested event,
    Emitter<ForumState> emit,
  ) async {
    if (!_canDelete) {
      emit(
        const ForumActionFailure('Anda tidak memiliki izin menghapus topik'),
      );
      emit(_buildLoaded());
      return;
    }
    final result = await deleteForum(event.id);

    if (result.isFailure) {
      emit(ForumActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }

    // Optimistic: buang dari daftar lokal supaya UI langsung responsif.
    _items = _items.where((e) => e.id != event.id).toList();
    if (_total != null && _total! > 0) _total = _total! - 1;
    _revisi++;
    emit(const ForumActionSuccess('Topik berhasil dihapus'));
    emit(_buildLoaded());
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  /// Simpulkan `sekolah_id` dari post yang sudah dimuat (field ada di
  /// `ForumResource`), karena tidak ada endpoint lain yang bisa diakses
  /// role siswa/guru untuk mendapatkannya.
  void _serapSekolahId() {
    if (_sekolahId != null) return;
    for (final item in _items) {
      if (item.sekolahId != null) {
        _sekolahId = item.sekolahId;
        return;
      }
    }
  }

  ForumLoaded _buildLoaded() => ForumLoaded(
    items: _items,
    search: _search,
    tipe: _tipe,
    hasMore: _hasMore,
    isLoadingMore: _sedangMuatLagi,
    revisi: _revisi,
    total: _total,
    userId: _userId,
    canCreate: _canCreate,
    canUpdate: _canUpdate,
    canDelete: _canDelete,
    sekolahId: _sekolahId,
  );
}
