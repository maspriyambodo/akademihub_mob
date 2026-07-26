import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ekstrakurikuler_entity.dart';
import '../../domain/entities/pendaftaran_ekskul_entity.dart';
import '../../domain/usecases/daftar_ekstrakurikuler_usecase.dart';
import '../../domain/usecases/get_ekstrakurikuler_usecase.dart';
import '../../domain/usecases/get_pendaftaran_usecase.dart';
import '../../domain/usecases/keluar_ekstrakurikuler_usecase.dart';

part 'ekstrakurikuler_event.dart';
part 'ekstrakurikuler_state.dart';

/// Sumber data tab "Semua Ekskul".
enum EkskulSumber {
  /// `GET /ekstrakurikuler/aktif` (default).
  aktif,

  /// `GET /ekstrakurikuler` — termasuk yang nonaktif.
  semua,
}

class EkstrakurikulerBloc
    extends Bloc<EkstrakurikulerEvent, EkstrakurikulerState> {
  final GetEkstrakurikulerAktifUseCase getEkstrakurikulerAktif;
  final GetEkstrakurikulerListUseCase getEkstrakurikulerList;
  final GetEkstrakurikulerByPembinaUseCase getEkstrakurikulerByPembina;
  final GetPendaftaranSiswaUseCase getPendaftaranSiswa;
  final GetRiwayatPendaftaranSiswaUseCase getRiwayatPendaftaranSiswa;
  final GetPendaftaranListUseCase getPendaftaranList;
  final DaftarEkstrakurikulerUseCase daftarEkstrakurikuler;
  final KeluarEkstrakurikulerUseCase keluarEkstrakurikuler;

  // ── Cache internal ─────────────────────────────────────────────────────────
  List<EkstrakurikulerEntity> _semua = const [];
  List<PendaftaranEkskulEntity> _keanggotaan = const [];
  List<PendaftaranEkskulEntity> _riwayat = const [];
  List<EkstrakurikulerEntity> _dibina = const [];

  String _role = 'admin';
  int? _siswaId;
  int? _guruId;
  bool _canManagePendaftaran = false;
  bool _canViewPendaftaran = false;

  EkskulSumber _sumber = EkskulSumber.aktif;
  String _search = '';
  String? _pesanTabSaya;

  EkstrakurikulerBloc({
    required this.getEkstrakurikulerAktif,
    required this.getEkstrakurikulerList,
    required this.getEkstrakurikulerByPembina,
    required this.getPendaftaranSiswa,
    required this.getRiwayatPendaftaranSiswa,
    required this.getPendaftaranList,
    required this.daftarEkstrakurikuler,
    required this.keluarEkstrakurikuler,
  }) : super(EkstrakurikulerInitial()) {
    on<EkstrakurikulerLoadRequested>(_onLoad);
    on<EkstrakurikulerRefreshRequested>(_onRefresh);
    on<EkstrakurikulerSumberChanged>(_onSumberChanged);
    on<EkstrakurikulerSearchChanged>(_onSearchChanged);
    on<EkstrakurikulerDaftarRequested>(_onDaftar);
    on<EkstrakurikulerKeluarRequested>(_onKeluar);
  }

  // ── Handler ────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    EkstrakurikulerLoadRequested event,
    Emitter<EkstrakurikulerState> emit,
  ) async {
    _role = event.role;
    _siswaId = event.siswaId;
    _guruId = event.guruId;
    _canManagePendaftaran = event.canManagePendaftaran;
    _canViewPendaftaran = event.canViewPendaftaran;
    emit(EkstrakurikulerLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    EkstrakurikulerRefreshRequested event,
    Emitter<EkstrakurikulerState> emit,
  ) async {
    if (state is! EkstrakurikulerLoaded) emit(EkstrakurikulerLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onSumberChanged(
    EkstrakurikulerSumberChanged event,
    Emitter<EkstrakurikulerState> emit,
  ) async {
    if (_sumber == event.sumber) return;
    _sumber = event.sumber;
    emit(EkstrakurikulerLoading());
    await _fetchAndEmit(emit);
  }

  void _onSearchChanged(
    EkstrakurikulerSearchChanged event,
    Emitter<EkstrakurikulerState> emit,
  ) {
    _search = event.keyword;
    if (state is EkstrakurikulerLoaded ||
        _semua.isNotEmpty ||
        _keanggotaan.isNotEmpty) {
      emit(_buildLoaded());
    }
  }

  Future<void> _onDaftar(
    EkstrakurikulerDaftarRequested event,
    Emitter<EkstrakurikulerState> emit,
  ) async {
    final siswaId = _siswaId;
    if (siswaId == null) {
      emit(const EkstrakurikulerActionFailure('ID siswa tidak tersedia'));
      emit(_buildLoaded());
      return;
    }
    if (!_canManagePendaftaran) {
      emit(
        const EkstrakurikulerActionFailure(
          'Anda tidak memiliki izin untuk mendaftar ekstrakurikuler',
        ),
      );
      emit(_buildLoaded());
      return;
    }

    final result = await daftarEkstrakurikuler(
      ekstrakurikulerId: event.ekstrakurikulerId,
      siswaId: siswaId,
    );

    if (result.isFailure) {
      emit(EkstrakurikulerActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }

    await _muatKeanggotaan();
    emit(const EkstrakurikulerActionSuccess('Berhasil mendaftar ekskul'));
    emit(_buildLoaded());
  }

  Future<void> _onKeluar(
    EkstrakurikulerKeluarRequested event,
    Emitter<EkstrakurikulerState> emit,
  ) async {
    if (!_canManagePendaftaran) {
      emit(
        const EkstrakurikulerActionFailure(
          'Anda tidak memiliki izin untuk keluar dari ekstrakurikuler',
        ),
      );
      emit(_buildLoaded());
      return;
    }

    final result = await keluarEkstrakurikuler(event.pendaftaranId);

    if (result.isFailure) {
      emit(EkstrakurikulerActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }

    await _muatKeanggotaan();
    emit(const EkstrakurikulerActionSuccess('Berhasil keluar dari ekskul'));
    emit(_buildLoaded());
  }

  // ── Pengambilan data ───────────────────────────────────────────────────────

  Future<void> _fetchAndEmit(Emitter<EkstrakurikulerState> emit) async {
    final hasilSemua = _sumber == EkskulSumber.aktif
        ? await getEkstrakurikulerAktif()
        : await getEkstrakurikulerList();

    if (hasilSemua.isFailure) {
      emit(EkstrakurikulerError(hasilSemua.requireFailure.message));
      return;
    }
    _semua = hasilSemua.requireData;

    await _muatKeanggotaan();
    emit(_buildLoaded());
  }

  /// Mengisi data tab "Ekskul Saya" sesuai role. Kegagalan di sini tidak
  /// mematikan seluruh halaman — pesan disimpan dan hanya tampil di tab itu.
  Future<void> _muatKeanggotaan() async {
    _pesanTabSaya = null;
    _keanggotaan = const [];
    _riwayat = const [];
    _dibina = const [];

    switch (_role) {
      case 'siswa':
      case 'wali':
        await _muatUntukSiswa();
        break;
      case 'guru':
        await _muatUntukGuru();
        break;
      default:
        // Admin: index pendaftaran memang boleh melihat seluruh data.
        await _muatSeluruhPendaftaran();
    }
  }

  Future<void> _muatUntukSiswa() async {
    final siswaId = _siswaId;
    if (!_canViewPendaftaran) {
      _pesanTabSaya =
          'Anda tidak memiliki izin melihat data pendaftaran ekstrakurikuler';
      return;
    }
    if (siswaId == null) {
      // Sengaja TIDAK jatuh ke `GET /ekstrakurikuler/pendaftaran`: endpoint
      // index itu tidak menerapkan `canAccessSiswaId()` seperti endpoint
      // `/siswa/{siswaId}`, sehingga akan menampilkan pendaftaran siswa lain.
      _pesanTabSaya = _role == 'wali'
          ? 'Profil wali tidak menyertakan ID siswa, sehingga daftar ekskul '
                'anak belum bisa ditampilkan. Endpoint daftar pendaftaran umum '
                'tidak dibatasi per sesi di backend, jadi tidak dipakai di sini.'
          : 'ID siswa tidak tersedia pada profil Anda';
      return;
    }

    final hasil = await getPendaftaranSiswa(siswaId);
    if (hasil.isFailure) {
      _pesanTabSaya = hasil.requireFailure.message;
      return;
    }
    _keanggotaan = hasil.requireData;

    final hasilRiwayat = await getRiwayatPendaftaranSiswa(siswaId);
    if (hasilRiwayat.isSuccess) {
      _riwayat = hasilRiwayat.requireData;
    }
  }

  Future<void> _muatUntukGuru() async {
    final guruId = _guruId;
    if (guruId == null) {
      _pesanTabSaya = 'ID guru tidak tersedia pada profil Anda';
      return;
    }
    final hasil = await getEkstrakurikulerByPembina(guruId);
    if (hasil.isFailure) {
      _pesanTabSaya = hasil.requireFailure.message;
      return;
    }
    _dibina = hasil.requireData;
  }

  /// Khusus admin: `GET /ekstrakurikuler/pendaftaran` mengembalikan seluruh
  /// pendaftaran (controller index tidak memanggil `canAccessSiswaId`).
  Future<void> _muatSeluruhPendaftaran() async {
    if (!_canViewPendaftaran) {
      _pesanTabSaya =
          'Anda tidak memiliki izin melihat data pendaftaran ekstrakurikuler';
      return;
    }
    final hasil = await getPendaftaranList(siswaId: _siswaId);
    if (hasil.isFailure) {
      _pesanTabSaya = hasil.requireFailure.message;
      return;
    }
    _riwayat = hasil.requireData;
    _keanggotaan = _riwayat.where((e) => e.isAktif).toList();
  }

  // ── Builder state ──────────────────────────────────────────────────────────

  EkstrakurikulerLoaded _buildLoaded() {
    final keyword = _search.trim().toLowerCase();

    // Pencarian disaring di klien: endpoint `/aktif` tidak menerima parameter
    // `search`, sehingga penyaringan konsisten untuk kedua sumber data.
    final semuaTersaring =
        _semua.where((e) {
            if (keyword.isEmpty) return true;
            return e.nama.toLowerCase().contains(keyword) ||
                (e.kode ?? '').toLowerCase().contains(keyword) ||
                (e.pembinaNama ?? '').toLowerCase().contains(keyword) ||
                (e.hari ?? '').toLowerCase().contains(keyword);
          }).toList()
          ..sort(
            (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
          );

    final riwayatUrut = List<PendaftaranEkskulEntity>.from(_riwayat)
      ..sort((a, b) {
        final da = a.tanggalDaftarDate;
        final db = b.tanggalDaftarDate;
        if (da == null && db == null) return b.id.compareTo(a.id);
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    return EkstrakurikulerLoaded(
      semua: semuaTersaring,
      keanggotaan: List<PendaftaranEkskulEntity>.unmodifiable(_keanggotaan),
      riwayat: List<PendaftaranEkskulEntity>.unmodifiable(riwayatUrut),
      dibina: List<EkstrakurikulerEntity>.unmodifiable(_dibina),
      sumber: _sumber,
      search: _search,
      role: _role,
      siswaId: _siswaId,
      guruId: _guruId,
      canManagePendaftaran: _canManagePendaftaran,
      canViewPendaftaran: _canViewPendaftaran,
      pesanTabSaya: _pesanTabSaya,
    );
  }
}
