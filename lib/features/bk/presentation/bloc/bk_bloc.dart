import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bk_kasus_entity.dart';
import '../../domain/usecases/get_bk_kasus_usecase.dart';

part 'bk_event.dart';
part 'bk_state.dart';

/// Bloc daftar kasus Bimbingan Konseling.
///
/// Sumber data per role (visibilitas sudah diverifikasi di
/// `BkKasusService::applySessionVisibilityFilter` backend):
/// - siswa  → `/bk/kasus/siswa/{siswaId}` (kasus miliknya sendiri),
/// - wali   → `/bk/kasus` (index; backend memfilter ke kasus anak-anaknya —
///   profil wali tidak memuat id siswa sehingga endpoint by-siswa tak bisa
///   dipakai),
/// - guru/guru BK → `/bk/kasus` (index; backend memfilter ke kasus yang ia
///   tangani), admin → semua.
class BkBloc extends Bloc<BkEvent, BkState> {
  final GetBkKasusListUseCase getKasusList;
  final GetBkKasusBySiswaUseCase getKasusBySiswa;

  // ── Cache internal ────────────────────────────────────────────────────────
  List<BkKasusEntity> _items = const [];
  String _role = '';
  int? _profileId;
  bool _canView = false;
  bool _canCreate = false;
  String? _filterStatus;
  String _search = '';

  /// Naik setiap kali `_items` berubah — entity `props` hanya `[id]` sehingga
  /// tanpa penanda ini Equatable menganggap daftar hasil muat-ulang identik.
  int _revisi = 0;

  BkBloc({required this.getKasusList, required this.getKasusBySiswa})
    : super(BkInitial()) {
    on<BkLoadRequested>(_onLoad);
    on<BkRefreshRequested>(_onRefresh);
    on<BkStatusFilterChanged>(_onStatusFilterChanged);
    on<BkSearchChanged>(_onSearchChanged);
  }

  Future<void> _onLoad(BkLoadRequested event, Emitter<BkState> emit) async {
    _role = event.role;
    _profileId = event.profileId;
    _canView = event.canView;
    _canCreate = event.canCreate;

    if (!_canView) {
      emit(
        const BkNoAccess(
          'Akun Anda tidak memiliki izin "bk-kasus.view" untuk melihat data '
          'Bimbingan Konseling. Hubungi admin sekolah bila menurut Anda ini '
          'keliru.',
        ),
      );
      return;
    }

    emit(BkLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    BkRefreshRequested event,
    Emitter<BkState> emit,
  ) async {
    if (!_canView) return;
    await _fetchAndEmit(emit);
  }

  Future<void> _onStatusFilterChanged(
    BkStatusFilterChanged event,
    Emitter<BkState> emit,
  ) async {
    if (state is! BkLoaded) return;
    _filterStatus = event.status == _filterStatus ? null : event.status;
    emit(_buildLoaded());
  }

  Future<void> _onSearchChanged(
    BkSearchChanged event,
    Emitter<BkState> emit,
  ) async {
    if (state is! BkLoaded) return;
    final baru = event.search.trim();
    if (baru == _search) return;
    _search = baru;
    emit(_buildLoaded());
  }

  Future<void> _fetchAndEmit(Emitter<BkState> emit) async {
    if (_role == 'siswa') {
      final siswaId = _profileId;
      if (siswaId == null) {
        emit(const BkError('Data profil siswa tidak tersedia'));
        return;
      }
      final result = await getKasusBySiswa(siswaId);
      if (result.isFailure) {
        emit(BkError(result.requireFailure.message));
        return;
      }
      _items = result.requireData;
    } else {
      final result = await getKasusList();
      if (result.isFailure) {
        emit(BkError(result.requireFailure.message));
        return;
      }
      _items = result.requireData;
    }

    _items = List.of(_items)
      ..sort((a, b) {
        final da = a.tanggalDate;
        final db = b.tanggalDate;
        if (da == null && db == null) return b.id.compareTo(a.id);
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da); // terbaru dulu
      });
    _revisi++;
    emit(_buildLoaded());
  }

  BkLoaded _buildLoaded() {
    var terfilter = _items;
    final f = _filterStatus;
    if (f != null) {
      terfilter = terfilter
          .where((e) => e.statusLabel.toLowerCase() == f)
          .toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      terfilter = terfilter.where((e) {
        return (e.siswaNama ?? '').toLowerCase().contains(q) ||
            (e.siswaNis ?? '').toLowerCase().contains(q) ||
            (e.jenisNama ?? '').toLowerCase().contains(q) ||
            (e.judul ?? '').toLowerCase().contains(q) ||
            (e.keterangan ?? '').toLowerCase().contains(q);
      }).toList();
    }

    final hitungStatus = <String, int>{};
    for (final e in _items) {
      final k = e.statusLabel.toLowerCase();
      hitungStatus[k] = (hitungStatus[k] ?? 0) + 1;
    }

    return BkLoaded(
      items: terfilter,
      totalSemua: _items.length,
      hitungStatus: hitungStatus,
      filterStatus: _filterStatus,
      search: _search,
      role: _role,
      canCreate: _canCreate,
      revisi: _revisi,
    );
  }
}
