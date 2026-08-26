import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/tugas_entity.dart';
import '../../domain/entities/tugas_item_entity.dart';
import '../../domain/entities/tugas_siswa_entity.dart';
import '../../domain/usecases/get_tugas_usecase.dart';
import '../../domain/usecases/get_pengumpulan_usecase.dart';
import '../../domain/usecases/kumpulkan_tugas_usecase.dart';

part 'tugas_event.dart';
part 'tugas_state.dart';

/// Filter status untuk tampilan siswa/wali.
enum TugasFilter { semua, belum, sudah }

class TugasBloc extends Bloc<TugasEvent, TugasState> {
  final GetTugasListUseCase getTugasList;
  final GetTugasByKelasUseCase getTugasByKelas;
  final GetTugasByGuruMapelUseCase getTugasByGuruMapel;
  final GetPengumpulanListUseCase getPengumpulanList;
  final GetPengumpulanBySiswaUseCase getPengumpulanBySiswa;
  final KumpulkanTugasUseCase kumpulkanTugas;

  // ── Cache internal ─────────────────────────────────────────────────────────
  List<TugasItemEntity> _all = const [];
  String _role = 'unknown';
  int? _siswaId;
  int? _kelasId;
  int? _guruId;
  int? _guruMapelId;
  bool _canSubmit = false;
  TugasFilter _filter = TugasFilter.semua;

  TugasBloc({
    required this.getTugasList,
    required this.getTugasByKelas,
    required this.getTugasByGuruMapel,
    required this.getPengumpulanList,
    required this.getPengumpulanBySiswa,
    required this.kumpulkanTugas,
  }) : super(TugasInitial()) {
    on<TugasLoadRequested>(_onLoad);
    on<TugasRefreshRequested>(_onRefresh);
    on<TugasFilterChanged>(_onFilterChanged);
    on<TugasSubmitRequested>(_onSubmit);
  }

  Future<void> _onLoad(
    TugasLoadRequested event,
    Emitter<TugasState> emit,
  ) async {
    _role = event.role;
    _siswaId = event.siswaId;
    _kelasId = event.kelasId;
    _guruId = event.guruId;
    _guruMapelId = event.guruMapelId;
    _canSubmit = event.canSubmit;
    emit(TugasLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    TugasRefreshRequested event,
    Emitter<TugasState> emit,
  ) async {
    emit(TugasLoading());
    await _fetchAndEmit(emit);
  }

  void _onFilterChanged(TugasFilterChanged event, Emitter<TugasState> emit) {
    _filter = event.filter;
    emit(_buildLoaded());
  }

  Future<void> _onSubmit(
    TugasSubmitRequested event,
    Emitter<TugasState> emit,
  ) async {
    final siswaId = _siswaId;
    if (_role != 'siswa' || !_canSubmit) {
      emit(
        const TugasActionFailure('Anda tidak memiliki izin mengumpulkan tugas'),
      );
      emit(_buildLoaded());
      return;
    }
    if (siswaId == null) {
      emit(const TugasActionFailure('ID siswa tidak tersedia'));
      emit(_buildLoaded());
      return;
    }

    final result = await kumpulkanTugas(
      siswaId: siswaId,
      tugasId: event.tugasId,
      jawaban: event.jawaban,
      fileJawaban: event.fileJawaban,
    );

    if (result.isSuccess) {
      final updated = result.requireData;
      _all = _all
          .map(
            (item) => item.tugas.id == event.tugasId
                ? TugasItemEntity(tugas: item.tugas, pengumpulan: updated)
                : item,
          )
          .toList();
      emit(const TugasActionSuccess('Tugas berhasil dikumpulkan'));
    } else {
      emit(TugasActionFailure(result.requireFailure.message));
    }
    emit(_buildLoaded());
  }

  // ── Pengambilan data per role ──────────────────────────────────────────────

  Future<void> _fetchAndEmit(Emitter<TugasState> emit) async {
    switch (_role) {
      case 'siswa':
        await _fetchSiswa(emit);
        break;
      case 'wali':
        await _fetchWali(emit);
        break;
      case 'guru':
        await _fetchGuru(emit);
        break;
      case 'admin':
        await _fetchUmum(emit);
        break;
      default:
        emit(const TugasError('Peran pengguna tidak dikenali'));
    }
  }

  Future<void> _fetchSiswa(Emitter<TugasState> emit) async {
    final kelasId = _kelasId;
    final tugasResult = kelasId != null
        ? await getTugasByKelas(kelasId)
        : await getTugasList();

    if (tugasResult.isFailure) {
      emit(TugasError(tugasResult.requireFailure.message));
      return;
    }

    final siswaId = _siswaId;
    final pengumpulanResult = siswaId != null
        ? await getPengumpulanBySiswa(siswaId)
        : await getPengumpulanList();

    final pengumpulan = pengumpulanResult.isSuccess
        ? pengumpulanResult.requireData
        : const <TugasSiswaEntity>[];

    _all = _merge(tugasResult.requireData, pengumpulan);
    emit(_buildLoaded());
  }

  Future<void> _fetchWali(Emitter<TugasState> emit) async {
    // Backend otomatis membatasi daftar pengumpulan ke anak-anak wali ini.
    final pengumpulanResult = await getPengumpulanList();
    final pengumpulan = pengumpulanResult.isSuccess
        ? pengumpulanResult.requireData
        : const <TugasSiswaEntity>[];

    final kelasIds = <int>{
      ?_kelasId,
      ...pengumpulan.map((e) => e.tugasKelasId).whereType<int>(),
    };

    final tugas = <TugasEntity>[];
    for (final kelasId in kelasIds) {
      final r = await getTugasByKelas(kelasId);
      if (r.isSuccess) tugas.addAll(r.requireData);
    }

    if (tugas.isEmpty) {
      // Fallback: kelas anak belum bisa disimpulkan → pakai daftar umum.
      final r = await getTugasList();
      if (r.isFailure && pengumpulan.isEmpty) {
        emit(TugasError(r.requireFailure.message));
        return;
      }
      if (r.isSuccess) tugas.addAll(r.requireData);
    }

    _all = _merge(_dedupe(tugas), pengumpulan);
    emit(_buildLoaded());
  }

  Future<void> _fetchGuru(Emitter<TugasState> emit) async {
    final guruMapelId = _guruMapelId;
    if (guruMapelId != null) {
      final result = await getTugasByGuruMapel(guruMapelId);
      if (result.isFailure) {
        emit(TugasError(result.requireFailure.message));
        return;
      }
      _all = _merge(result.requireData, const []);
      emit(_buildLoaded());
      return;
    }

    // Profil guru hanya menyimpan id guru (bukan id guru-mapel), sehingga
    // daftar umum diambil lalu disaring berdasarkan guru pada relasi guru_mapel.
    final result = await getTugasList();
    if (result.isFailure) {
      emit(TugasError(result.requireFailure.message));
      return;
    }

    final guruId = _guruId;
    final tugas = guruId == null
        ? result.requireData
        : result.requireData.where((t) => t.guruId == guruId).toList();

    _all = _merge(tugas, const []);
    emit(_buildLoaded());
  }

  Future<void> _fetchUmum(Emitter<TugasState> emit) async {
    final result = await getTugasList();
    if (result.isFailure) {
      emit(TugasError(result.requireFailure.message));
      return;
    }
    _all = _merge(result.requireData, const []);
    emit(_buildLoaded());
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  List<TugasEntity> _dedupe(List<TugasEntity> items) {
    final seen = <int>{};
    return items.where((t) => seen.add(t.id)).toList();
  }

  List<TugasItemEntity> _merge(
    List<TugasEntity> tugas,
    List<TugasSiswaEntity> pengumpulan,
  ) {
    final byTugasId = <int, TugasSiswaEntity>{};
    for (final p in pengumpulan) {
      final id = p.tugasId;
      if (id != null) byTugasId[id] = p;
    }

    final items = tugas
        .map((t) => TugasItemEntity(tugas: t, pengumpulan: byTugasId[t.id]))
        .toList();

    items.sort((a, b) {
      final da = a.tugas.tenggatWaktuDate;
      final db = b.tugas.tenggatWaktuDate;
      if (da == null && db == null) return b.tugas.id.compareTo(a.tugas.id);
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da); // deadline terbaru di atas
    });

    return items;
  }

  TugasLoaded _buildLoaded() {
    final belum = _all.where((e) => !e.sudahDikumpulkan).length;
    final sudah = _all.length - belum;

    final filtered = switch (_filter) {
      TugasFilter.semua => _all,
      TugasFilter.belum => _all.where((e) => !e.sudahDikumpulkan).toList(),
      TugasFilter.sudah => _all.where((e) => e.sudahDikumpulkan).toList(),
    };

    return TugasLoaded(
      items: filtered,
      allItems: _all,
      totalSemua: _all.length,
      totalBelum: belum,
      totalSudah: sudah,
      filter: _filter,
      role: _role,
      siswaId: _siswaId,
    );
  }
}
