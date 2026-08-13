import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/entities/tmb_tes_entity.dart';
import '../../domain/repositories/tmb_repository.dart';
import '../../domain/usecases/daftar_tmb_peserta_usecase.dart';
import '../../domain/usecases/get_tmb_peserta_by_siswa_usecase.dart';
import '../../domain/usecases/get_tmb_tes_by_kelas_usecase.dart';
import '../../domain/usecases/get_tmb_tes_list_usecase.dart';

part 'tmb_event.dart';
part 'tmb_state.dart';

/// Bloc daftar tes minat bakat.
///
/// Mode siswa: gabungan `GET /tes-minat-bakat/kelas/{kelasId}` dan
/// `GET /tes-minat-bakat-peserta/siswa/{siswaId}` — setiap tes ditampilkan
/// beserta status keikutsertaan siswa. Mode staf (admin/guru BK): daftar
/// seluruh tes dari endpoint index.
class TmbBloc extends Bloc<TmbEvent, TmbState> {
  final GetTmbTesListUseCase getTesList;
  final GetTmbTesByKelasUseCase getTesByKelas;
  final GetTmbPesertaBySiswaUseCase getPesertaBySiswa;
  final DaftarTmbPesertaUseCase daftarPeserta;

  String _role = 'admin';
  int? _siswaId;
  int? _kelasId;
  bool _hasViewTes = false;
  bool _canDaftar = false;
  bool _canMulai = false;
  bool _canSelesaikan = false;
  bool _canKirimJawaban = false;
  bool _canViewPeserta = false;
  bool _canViewPertanyaanEndpoint = false;
  bool _canViewHasilEndpoint = false;

  TmbBloc({
    required this.getTesList,
    required this.getTesByKelas,
    required this.getPesertaBySiswa,
    required this.daftarPeserta,
  }) : super(TmbInitial()) {
    on<TmbLoadRequested>(_onLoad);
    on<TmbRefreshRequested>(_onRefresh);
    on<TmbDaftarRequested>(_onDaftar);
  }

  bool get _isModeSiswa => _role == 'siswa' || _role == 'wali';

  Future<void> _onLoad(TmbLoadRequested event, Emitter<TmbState> emit) async {
    _role = event.role;
    _siswaId = event.siswaId;
    _kelasId = event.kelasId;
    _hasViewTes = event.hasViewTes;
    _canDaftar = event.canDaftar;
    _canMulai = event.canMulai;
    _canSelesaikan = event.canSelesaikan;
    _canKirimJawaban = event.canKirimJawaban;
    _canViewPeserta = event.canViewPeserta;
    _canViewPertanyaanEndpoint = event.canViewPertanyaanEndpoint;
    _canViewHasilEndpoint = event.canViewHasilEndpoint;

    if (!_hasViewTes) {
      emit(
        const TmbNoAccess(
          'Akun Anda tidak memiliki izin melihat tes minat bakat. '
          'Hubungi admin sekolah bila merasa seharusnya punya akses.',
        ),
      );
      return;
    }

    emit(TmbLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    TmbRefreshRequested event,
    Emitter<TmbState> emit,
  ) async {
    if (!_hasViewTes) return;
    if (state is! TmbLoaded) emit(TmbLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onDaftar(
    TmbDaftarRequested event,
    Emitter<TmbState> emit,
  ) async {
    final tampil = state;
    if (tampil is! TmbLoaded) return;

    final siswaId = _siswaId;
    if (!_canDaftar || siswaId == null) {
      emit(
        const TmbActionFailure(
          'Anda tidak memiliki izin mendaftar sebagai peserta tes',
        ),
      );
      emit(tampil);
      return;
    }

    final result = await daftarPeserta(tesId: event.tesId, siswaId: siswaId);
    if (result.isFailure) {
      emit(TmbActionFailure(result.requireFailure.message));
      emit(tampil);
      return;
    }

    emit(const TmbActionSuccess('Berhasil terdaftar sebagai peserta tes'));
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<TmbState> emit) async {
    if (_isModeSiswa) {
      await _fetchModeSiswa(emit);
    } else {
      await _fetchModeStaf(emit);
    }
  }

  Future<void> _fetchModeSiswa(Emitter<TmbState> emit) async {
    final siswaId = _siswaId;
    if (siswaId == null) {
      emit(const TmbError('ID siswa tidak ditemukan pada profil Anda'));
      return;
    }

    String? catatan;

    // 1) Keikutsertaan siswa (memuat relasi tes + hasil).
    final hasilPeserta = await getPesertaBySiswa(siswaId);
    if (hasilPeserta.isFailure) {
      final f = hasilPeserta.requireFailure;
      if (f is TmbAccessFailure) {
        emit(TmbNoAccess(f.message));
      } else {
        emit(TmbError(f.message));
      }
      return;
    }
    final pesertaList = hasilPeserta.requireData;

    // 2) Tes yang beredar di kelas siswa. Endpoint by-kelas hanya
    //    mengembalikan tes yang SUDAH punya peserta dari kelas tsb, jadi
    //    hasilnya digabung dengan tes dari keikutsertaan sendiri.
    var tesKelas = const <TmbTesEntity>[];
    if (_kelasId != null) {
      final hasilTes = await getTesByKelas(_kelasId!);
      if (hasilTes.isSuccess) {
        tesKelas = hasilTes.requireData;
      } else {
        catatan =
            'Daftar tes kelas gagal dimuat: '
            '${hasilTes.requireFailure.message}';
      }
    } else {
      catatan =
          'Kelas tidak ditemukan pada profil, hanya tes yang sudah Anda '
          'ikuti yang ditampilkan.';
    }

    final pesertaPerTes = <int, TmbPesertaEntity>{
      for (final p in pesertaList) p.tesId: p,
    };

    final items = <TmbTesItem>[];
    final tesTerpakai = <int>{};
    for (final tes in tesKelas) {
      tesTerpakai.add(tes.id);
      items.add(TmbTesItem(tes: tes, peserta: pesertaPerTes[tes.id]));
    }
    for (final p in pesertaList) {
      if (tesTerpakai.contains(p.tesId)) continue;
      final tes = p.tes;
      if (tes == null) continue;
      items.add(TmbTesItem(tes: tes, peserta: p));
    }
    _urutkan(items);

    emit(_buildLoaded(items: items, catatan: catatan));
  }

  Future<void> _fetchModeStaf(Emitter<TmbState> emit) async {
    final hasilTes = await getTesList();
    if (hasilTes.isFailure) {
      final f = hasilTes.requireFailure;
      if (f is TmbAccessFailure) {
        emit(TmbNoAccess(f.message));
      } else {
        emit(TmbError(f.message));
      }
      return;
    }

    final items = hasilTes.requireData
        .map((tes) => TmbTesItem(tes: tes))
        .toList();
    _urutkan(items);

    emit(_buildLoaded(items: items));
  }

  void _urutkan(List<TmbTesItem> items) {
    items.sort((a, b) {
      final da = a.tes.waktuMulaiDate;
      final db = b.tes.waktuMulaiDate;
      if (da == null && db == null) return b.tes.id.compareTo(a.tes.id);
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
  }

  TmbLoaded _buildLoaded({required List<TmbTesItem> items, String? catatan}) {
    return TmbLoaded(
      items: List<TmbTesItem>.unmodifiable(items),
      isModeSiswa: _isModeSiswa,
      role: _role,
      siswaId: _siswaId,
      canDaftar: _canDaftar && _siswaId != null,
      canMulai: _canMulai,
      canSelesaikan: _canSelesaikan,
      canKirimJawaban: _canKirimJawaban,
      canViewPeserta: _canViewPeserta,
      canViewPertanyaanEndpoint: _canViewPertanyaanEndpoint,
      canViewHasilEndpoint: _canViewHasilEndpoint,
      catatan: catatan,
    );
  }
}
