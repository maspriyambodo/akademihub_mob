import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ppdb_gelombang_entity.dart';
import '../../domain/entities/ppdb_pendaftar_entity.dart';
import '../../domain/entities/ppdb_statistik_entity.dart';
import '../../domain/repositories/ppdb_repository.dart';
import '../../domain/usecases/get_ppdb_gelombang_usecase.dart';
import '../../domain/usecases/get_ppdb_pendaftar_usecase.dart';
import '../../domain/usecases/get_ppdb_statistik_usecase.dart';

part 'ppdb_event.dart';
part 'ppdb_state.dart';

class PpdbBloc extends Bloc<PpdbEvent, PpdbState> {
  final GetPpdbGelombangUseCase getGelombang;
  final GetPpdbPendaftarUseCase getPendaftar;
  final GetPpdbStatistikUseCase getStatistik;

  // ── Cache sisi klien ──────────────────────────────────────────────────────
  List<PpdbGelombangEntity> _gelombangList = const [];
  List<PpdbPendaftarEntity> _pendaftarList = const [];
  PpdbStatistikEntity _statistik = PpdbStatistikEntity.kosong;

  String _role = '';
  bool _bolehLihatPendaftar = false;
  bool _bolehLihatGelombang = false;

  String _search = '';
  String? _filterStatus;
  int? _filterGelombangId;

  /// Penjaga balapan: hanya hasil permintaan terbaru yang boleh di-emit.
  int _versiPermintaan = 0;

  /// Penanda unik tiap Loaded supaya Equatable tidak menganggapnya sama
  /// (entity membandingkan diri hanya lewat `id`).
  int _versiState = 0;

  PpdbBloc({
    required this.getGelombang,
    required this.getPendaftar,
    required this.getStatistik,
  }) : super(PpdbInitial()) {
    on<PpdbLoadRequested>(_onLoad);
    on<PpdbRefreshRequested>(_onRefresh);
    on<PpdbMuatUlangSenyap>(_onMuatUlangSenyap);
    on<PpdbSearchChanged>(_onSearchChanged);
    on<PpdbStatusFilterChanged>(_onStatusFilterChanged);
    on<PpdbGelombangFilterChanged>(_onGelombangFilterChanged);
  }

  Future<void> _onLoad(PpdbLoadRequested event, Emitter<PpdbState> emit) async {
    _role = event.role;
    _bolehLihatPendaftar = event.bolehLihatPendaftar;
    _bolehLihatGelombang = event.bolehLihatGelombang;

    if (!_bolehLihatPendaftar) {
      emit(PpdbForbidden(_pesanTanpaIzin()));
      return;
    }

    emit(PpdbLoading());
    await _muatSemua(emit);
  }

  Future<void> _onRefresh(
    PpdbRefreshRequested event,
    Emitter<PpdbState> emit,
  ) async {
    if (!_bolehLihatPendaftar) {
      emit(PpdbForbidden(_pesanTanpaIzin()));
      return;
    }
    if (state is! PpdbLoaded) emit(PpdbLoading());
    await _muatSemua(emit);
  }

  /// Muat ulang tanpa menampilkan state Loading — dipakai saat kembali dari
  /// halaman detail (status pendaftar bisa saja berubah di sana).
  Future<void> _onMuatUlangSenyap(
    PpdbMuatUlangSenyap event,
    Emitter<PpdbState> emit,
  ) async {
    if (!_bolehLihatPendaftar || state is! PpdbLoaded) return;
    await _muatSemua(emit);
  }

  Future<void> _onSearchChanged(
    PpdbSearchChanged event,
    Emitter<PpdbState> emit,
  ) async {
    if (_search == event.search.trim()) return;
    _search = event.search.trim();
    await _muatDaftar(emit);
  }

  Future<void> _onStatusFilterChanged(
    PpdbStatusFilterChanged event,
    Emitter<PpdbState> emit,
  ) async {
    _filterStatus = event.status;
    await _muatDaftar(emit);
  }

  Future<void> _onGelombangFilterChanged(
    PpdbGelombangFilterChanged event,
    Emitter<PpdbState> emit,
  ) async {
    _filterGelombangId = event.gelombangId;
    await _muatDaftar(emit);
  }

  // ── Pengambilan data ──────────────────────────────────────────────────────

  Future<void> _muatSemua(Emitter<PpdbState> emit) async {
    final versi = ++_versiPermintaan;

    // Gelombang bersifat pelengkap: kegagalannya tidak menggagalkan halaman.
    if (_bolehLihatGelombang) {
      final hasilGelombang = await getGelombang();
      if (versi != _versiPermintaan) return;
      if (hasilGelombang.isSuccess) {
        _gelombangList = hasilGelombang.requireData;
      }
    } else {
      _gelombangList = const [];
    }

    final hasilPendaftar = await getPendaftar(
      search: _search.isEmpty ? null : _search,
      statusPendaftaran: _filterStatus,
      gelombangId: _filterGelombangId,
    );
    if (versi != _versiPermintaan) return;

    if (hasilPendaftar.isFailure) {
      final failure = hasilPendaftar.requireFailure;
      if (failure is PpdbAccessFailure) {
        emit(PpdbForbidden(_pesanTanpaIzin(failure.message)));
      } else {
        emit(PpdbError(failure.message));
      }
      return;
    }
    _pendaftarList = hasilPendaftar.requireData;

    await _muatStatistik(versi);
    if (versi != _versiPermintaan) return;

    emit(_bangunLoaded());
  }

  /// Hanya memuat ulang daftar pendaftar (saat search/filter berubah);
  /// statistik dan gelombang memakai cache.
  Future<void> _muatDaftar(Emitter<PpdbState> emit) async {
    if (!_bolehLihatPendaftar) return;
    final versi = ++_versiPermintaan;

    if (state is PpdbLoaded) {
      emit(_bangunLoaded(sedangMemuatDaftar: true));
    } else {
      emit(PpdbLoading());
    }

    final hasil = await getPendaftar(
      search: _search.isEmpty ? null : _search,
      statusPendaftaran: _filterStatus,
      gelombangId: _filterGelombangId,
    );
    if (versi != _versiPermintaan) return;

    if (hasil.isFailure) {
      final failure = hasil.requireFailure;
      if (failure is PpdbAccessFailure) {
        emit(PpdbForbidden(_pesanTanpaIzin(failure.message)));
      } else {
        emit(PpdbError(failure.message));
      }
      return;
    }
    _pendaftarList = hasil.requireData;
    emit(_bangunLoaded());
  }

  /// Statistik agregat via endpoint backend
  /// `/ppdb/pendaftaran/sekolah/{sekolahId}/statistics`. `sekolah_id` tidak
  /// tersedia di profil user mobile, jadi diturunkan dari data gelombang /
  /// pendaftar yang sudah termuat. Bila tidak bisa ditentukan, statistik
  /// dihitung dari daftar yang termuat di klien (maks. 200 baris).
  Future<void> _muatStatistik(int versi) async {
    int? sekolahId;
    for (final g in _gelombangList) {
      if (g.sekolahId != null) {
        sekolahId = g.sekolahId;
        break;
      }
    }
    if (sekolahId == null) {
      for (final p in _pendaftarList) {
        if (p.sekolahId != null) {
          sekolahId = p.sekolahId;
          break;
        }
      }
    }

    if (sekolahId != null) {
      final hasil = await getStatistik(sekolahId: sekolahId);
      if (versi != _versiPermintaan) return;
      if (hasil.isSuccess) {
        _statistik = hasil.requireData;
        return;
      }
    }
    _statistik = _hitungStatistikKlien();
  }

  PpdbStatistikEntity _hitungStatistikKlien() {
    var draft = 0;
    var terverifikasi = 0;
    var seleksi = 0;
    var diterima = 0;
    var cadangan = 0;
    var ditolak = 0;
    for (final p in _pendaftarList) {
      switch (p.statusPendaftaran) {
        case 'draft':
          draft++;
        case 'terverifikasi':
          terverifikasi++;
        case 'seleksi':
          seleksi++;
        case 'diterima':
          diterima++;
        case 'cadangan':
          cadangan++;
        case 'ditolak':
          ditolak++;
      }
    }
    return PpdbStatistikEntity(
      total: _pendaftarList.length,
      draft: draft,
      terverifikasi: terverifikasi,
      seleksi: seleksi,
      diterima: diterima,
      cadangan: cadangan,
      ditolak: ditolak,
      dariServer: false,
    );
  }

  PpdbLoaded _bangunLoaded({bool sedangMemuatDaftar = false}) {
    PpdbGelombangEntity? aktif;
    for (final g in _gelombangList) {
      if (g.isActive) {
        aktif = g;
        break;
      }
    }

    return PpdbLoaded(
      statistik: _statistik,
      gelombangList: _gelombangList,
      gelombangAktif: aktif,
      pendaftarList: _pendaftarList,
      search: _search,
      filterStatus: _filterStatus,
      filterGelombangId: _filterGelombangId,
      sedangMemuatDaftar: sedangMemuatDaftar,
      versi: ++_versiState,
    );
  }

  String _pesanTanpaIzin([String? dariServer]) {
    if (dariServer != null && dariServer.trim().isNotEmpty) {
      final lower = dariServer.toLowerCase();
      // Pesan bawaan middleware berbahasa Inggris; ganti dengan pesan lokal.
      if (!lower.contains('permission') &&
          !lower.contains('forbidden') &&
          !lower.contains('unauthorized')) {
        return dariServer;
      }
    }
    final peran = _role.trim().isEmpty ? 'akun Anda' : 'peran $_role';
    return 'Monitoring PPDB hanya dapat diakses oleh pengelola PPDB sekolah '
        '(izin "ppdb.pendaftaran.view"). Saat ini $peran belum memilikinya. '
        'Hubungi admin sekolah bila Anda memerlukan akses.';
  }
}
