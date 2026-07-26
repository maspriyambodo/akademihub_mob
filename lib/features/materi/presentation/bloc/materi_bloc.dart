import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/log_akses_materi_entity.dart';
import '../../domain/entities/materi_entity.dart';
import '../../domain/entities/materi_group_entity.dart';
import '../../domain/usecases/get_materi_usecase.dart';

part 'materi_event.dart';
part 'materi_state.dart';

class MateriBloc extends Bloc<MateriEvent, MateriState> {
  final GetMateriListUseCase getMateriList;
  final GetMateriByGuruMapelUseCase getMateriByGuruMapel;
  final GetMateriPopulerUseCase getMateriPopuler;

  // ── Cache internal ─────────────────────────────────────────────────────────
  List<MateriEntity> _all = const [];
  List<MateriPopulerEntity> _populer = const [];
  String _role = 'admin';
  int? _siswaId;
  int? _kelasId;
  int? _guruId;
  int? _guruMapelId;
  String _search = '';
  String? _mapelTerpilih;

  MateriBloc({
    required this.getMateriList,
    required this.getMateriByGuruMapel,
    required this.getMateriPopuler,
  }) : super(MateriInitial()) {
    on<MateriLoadRequested>(_onLoad);
    on<MateriRefreshRequested>(_onRefresh);
    on<MateriSearchChanged>(_onSearchChanged);
    on<MateriMapelFilterChanged>(_onMapelChanged);
  }

  Future<void> _onLoad(
    MateriLoadRequested event,
    Emitter<MateriState> emit,
  ) async {
    _role = event.role;
    _siswaId = event.siswaId;
    _kelasId = event.kelasId;
    _guruId = event.guruId;
    _guruMapelId = event.guruMapelId;
    emit(MateriLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    MateriRefreshRequested event,
    Emitter<MateriState> emit,
  ) async {
    emit(MateriLoading());
    await _fetchAndEmit(emit);
  }

  void _onSearchChanged(MateriSearchChanged event, Emitter<MateriState> emit) {
    _search = event.query;
    if (state is MateriLoaded || _all.isNotEmpty) emit(_buildLoaded());
  }

  void _onMapelChanged(
    MateriMapelFilterChanged event,
    Emitter<MateriState> emit,
  ) {
    _mapelTerpilih = event.mapel;
    if (state is MateriLoaded || _all.isNotEmpty) emit(_buildLoaded());
  }

  // ── Pengambilan data per role ──────────────────────────────────────────────

  Future<void> _fetchAndEmit(Emitter<MateriState> emit) async {
    switch (_role) {
      case 'guru':
        await _fetchGuru(emit);
        break;
      default:
        // Siswa & wali: backend sudah membatasi daftar ke guru-mapel yang
        // dapat mereka akses (`applyPortalMateriFilters`). Admin: seluruhnya.
        await _fetchUmum(emit);
    }
  }

  Future<void> _fetchUmum(Emitter<MateriState> emit) async {
    final hasil = await getMateriList();
    if (hasil.isFailure) {
      emit(MateriError(hasil.requireFailure.message));
      return;
    }
    _all = _urutkan(hasil.requireData);
    await _muatPopuler();
    emit(_buildLoaded());
  }

  Future<void> _fetchGuru(Emitter<MateriState> emit) async {
    final guruMapelId = _guruMapelId;
    if (guruMapelId != null) {
      final hasil = await getMateriByGuruMapel(guruMapelId);
      if (hasil.isFailure) {
        emit(MateriError(hasil.requireFailure.message));
        return;
      }
      _all = _urutkan(hasil.requireData);
      await _muatPopuler();
      emit(_buildLoaded());
      return;
    }

    // `/auth/me` hanya memuat id `mst_guru` pada profil guru (tanpa
    // `guru_mapel_id`), sehingga daftar umum diambil lalu disaring berdasarkan
    // `guru_mapel.guru.id` — sama seperti fitur tugas.
    final hasil = await getMateriList();
    if (hasil.isFailure) {
      emit(MateriError(hasil.requireFailure.message));
      return;
    }

    final guruId = _guruId;
    final materi = guruId == null
        ? hasil.requireData
        : hasil.requireData.where((m) => m.guruId == guruId).toList();

    _all = _urutkan(materi);
    await _muatPopuler();
    emit(_buildLoaded());
  }

  /// Materi populer bersifat pelengkap — kegagalannya diabaikan diam-diam.
  Future<void> _muatPopuler() async {
    if (_role == 'siswa' || _role == 'wali') {
      _populer = const [];
      return;
    }
    final hasil = await getMateriPopuler(limit: 5);
    _populer = hasil.isSuccess
        ? hasil.requireData
        : const <MateriPopulerEntity>[];
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  List<MateriEntity> _urutkan(List<MateriEntity> items) {
    final hasil = [...items]
      ..sort((a, b) {
        final da = a.createdAtDate;
        final db = b.createdAtDate;
        if (da == null && db == null) return b.id.compareTo(a.id);
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da); // terbaru di atas
      });
    return hasil;
  }

  List<MateriGroupEntity> _kelompokkan(List<MateriEntity> items) {
    final urutanLabel = <String>[];
    final peta = <String, List<MateriEntity>>{};
    final idPerLabel = <String, int?>{};

    for (final m in items) {
      final label = m.mapelLabel;
      if (!peta.containsKey(label)) {
        peta[label] = <MateriEntity>[];
        urutanLabel.add(label);
        idPerLabel[label] = m.mapelId;
      }
      peta[label]!.add(m);
    }

    urutanLabel.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return urutanLabel
        .map(
          (label) => MateriGroupEntity(
            mapelId: idPerLabel[label],
            mapelLabel: label,
            items: peta[label]!,
          ),
        )
        .toList();
  }

  MateriLoaded _buildLoaded() {
    final query = _search.trim().toLowerCase();

    final terfilter = _all.where((m) {
      if (_mapelTerpilih != null && m.mapelLabel != _mapelTerpilih) {
        return false;
      }
      if (query.isEmpty) return true;
      return m.haystack.contains(query);
    }).toList();

    // Pengelompokan hanya bermakna bila relasi mapel benar-benar terbaca.
    final adaMapel = _all.any((m) => m.mapelId != null || m.mapelNama != null);

    final opsiMapel = _all.map((m) => m.mapelLabel).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return MateriLoaded(
      items: terfilter,
      groups: _kelompokkan(terfilter),
      allItems: _all,
      populer: _populer,
      opsiMapel: opsiMapel,
      mapelTerpilih: _mapelTerpilih,
      search: _search,
      dikelompokkan: adaMapel && opsiMapel.length > 1,
      role: _role,
      siswaId: _siswaId,
      kelasId: _kelasId,
    );
  }
}
