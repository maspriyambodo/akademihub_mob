import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/nilai_entity.dart';
import '../../domain/entities/nilai_summary_entity.dart';
import '../../domain/usecases/get_nilai_siswa_usecase.dart';
import '../../domain/usecases/get_nilai_general_usecase.dart';
import '../../domain/usecases/create_nilai_usecase.dart';
import '../../domain/usecases/update_nilai_usecase.dart';
import '../../domain/usecases/delete_nilai_usecase.dart';

part 'nilai_event.dart';
part 'nilai_state.dart';

class NilaiBloc extends Bloc<NilaiEvent, NilaiState> {
  final GetNilaiSiswaUseCase getNilaiSiswa;
  final GetNilaiGeneralUseCase getNilaiGeneral;
  final GetNilaiUjianUseCase getNilaiUjian;
  final GetRataRataNilaiUseCase getRataRataNilai;
  final CreateNilaiUseCase createNilai;
  final UpdateNilaiUseCase updateNilai;
  final DeleteNilaiUseCase deleteNilai;

  // ── Cache internal (data mentah sebelum difilter) ──────────────────────────
  List<NilaiEntity> _all = [];
  List<NilaiEntity> _ujianItems = [];
  double? _rataRataServer;

  String _role = '';
  int? _profileId;
  String _search = '';
  String? _semester;
  int? _ujianId;

  NilaiBloc({
    required this.getNilaiSiswa,
    required this.getNilaiGeneral,
    required this.getNilaiUjian,
    required this.getRataRataNilai,
    required this.createNilai,
    required this.updateNilai,
    required this.deleteNilai,
  }) : super(NilaiInitial()) {
    on<NilaiLoadRequested>(_onLoad);
    on<NilaiRefreshRequested>(_onRefresh);
    on<NilaiSearchChanged>(_onSearchChanged);
    on<NilaiSemesterChanged>(_onSemesterChanged);
    on<NilaiUjianSelected>(_onUjianSelected);
    on<NilaiCreateRequested>(_onCreate);
    on<NilaiUpdateRequested>(_onUpdate);
    on<NilaiDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    NilaiLoadRequested event,
    Emitter<NilaiState> emit,
  ) async {
    _role = event.role;
    _profileId = event.profileId;
    _search = '';
    _semester = null;
    _ujianId = null;
    emit(NilaiLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    NilaiRefreshRequested event,
    Emitter<NilaiState> emit,
  ) async {
    _all = [];
    _ujianItems = [];
    _rataRataServer = null;
    emit(NilaiLoading());
    await _fetchAndEmit(emit);
  }

  void _onSearchChanged(NilaiSearchChanged event, Emitter<NilaiState> emit) {
    _search = event.query;
    emit(_buildLoaded());
  }

  void _onSemesterChanged(
    NilaiSemesterChanged event,
    Emitter<NilaiState> emit,
  ) {
    _semester = event.semester;
    emit(_buildLoaded());
  }

  Future<void> _onUjianSelected(
    NilaiUjianSelected event,
    Emitter<NilaiState> emit,
  ) async {
    _ujianId = event.ujianId;
    if (_ujianId == null) {
      _ujianItems = [];
      emit(_buildLoaded());
      return;
    }

    emit(NilaiLoading());
    final result = await getNilaiUjian(_ujianId!);
    if (result.isSuccess) {
      _ujianItems = result.requireData;
      emit(_buildLoaded());
    } else {
      emit(NilaiError(result.requireFailure.message));
    }
  }

  Future<void> _onCreate(
    NilaiCreateRequested event,
    Emitter<NilaiState> emit,
  ) async {
    final result = await createNilai(
      siswaId: event.siswaId,
      ujianId: event.ujianId,
      nilai: event.nilai,
      keterangan: event.keterangan,
    );
    await _completeMutation(result.isSuccess, result.isSuccess ? null : result.requireFailure.message, 'Nilai ditambahkan', emit);
  }

  Future<void> _onUpdate(
    NilaiUpdateRequested event,
    Emitter<NilaiState> emit,
  ) async {
    final result = await updateNilai(
      id: event.id,
      nilai: event.nilai,
      keterangan: event.keterangan,
    );
    await _completeMutation(result.isSuccess, result.isSuccess ? null : result.requireFailure.message, 'Nilai diperbarui', emit);
  }

  Future<void> _onDelete(
    NilaiDeleteRequested event,
    Emitter<NilaiState> emit,
  ) async {
    final result = await deleteNilai(event.id);
    await _completeMutation(result.isSuccess, result.isSuccess ? null : result.requireFailure.message, 'Nilai dihapus', emit);
  }

  Future<void> _completeMutation(
    bool success,
    String? failure,
    String message,
    Emitter<NilaiState> emit,
  ) async {
    if (!success) {
      emit(NilaiActionFailure(failure!));
      return;
    }
    emit(NilaiActionSuccess(message));
    _all = [];
    _ujianItems = [];
    _rataRataServer = null;
    await _fetchAndEmit(emit);
  }

  // ── Fetch ───────────────────────────────────────────────────────────────────

  Future<void> _fetchAndEmit(Emitter<NilaiState> emit) async {
    if (_role == 'siswa' && _profileId != null) {
      final result = await getNilaiSiswa(_profileId!);
      if (result.isFailure) {
        emit(NilaiError(result.requireFailure.message));
        return;
      }
      _all = result.requireData;

      // Rata-rata resmi dari backend; kegagalan di sini tidak fatal karena
      // rata-rata masih bisa dihitung dari daftar nilai.
      final rataResult = await getRataRataNilai(_profileId!);
      _rataRataServer = rataResult.isSuccess ? rataResult.requireData : null;

      emit(_buildLoaded());
      return;
    }

    // guru / wali / admin (dan siswa tanpa profileId):
    // endpoint index sudah dibatasi backend sesuai role yang login.
    final result = await getNilaiGeneral();
    if (result.isSuccess) {
      _all = result.requireData;
      _rataRataServer = null;
      emit(_buildLoaded());
    } else {
      emit(NilaiError(result.requireFailure.message));
    }
  }

  // ── Build state ─────────────────────────────────────────────────────────────

  NilaiLoaded _buildLoaded() {
    final isUjianMode = _ujianId != null;
    final source = isUjianMode ? _ujianItems : _all;

    var items = source;

    // Filter semester hanya relevan saat data punya info ujian.
    final semester = _semester;
    if (!isUjianMode && semester != null) {
      items = items.where((e) => e.semesterLabel == semester).toList();
    }

    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((e) => _matches(e, query)).toList();
    }

    final sorted = List<NilaiEntity>.from(items)..sort(_compare);

    return NilaiLoaded(
      role: _role,
      items: sorted,
      summary: _computeSummary(sorted),
      semesterOptions: _semesterOptions(_all),
      selectedSemester: _semester,
      ujianOptions: _ujianOptions(_all),
      selectedUjianId: _ujianId,
      searchQuery: _search,
    );
  }

  bool _matches(NilaiEntity e, String query) {
    final haystack = [
      e.siswaNama,
      e.siswaNis,
      e.mapelNama,
      e.ujianNama,
      e.jenisPenilaian,
      e.kelasNama,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(query);
  }

  int _compare(NilaiEntity a, NilaiEntity b) {
    // Urut per mapel, lalu tanggal terbaru, lalu nama siswa.
    final byMapel = a.mapelLabel.toLowerCase().compareTo(
      b.mapelLabel.toLowerCase(),
    );
    if (byMapel != 0) return byMapel;

    final ta = a.tanggalUjian ?? '';
    final tb = b.tanggalUjian ?? '';
    if (ta != tb) return tb.compareTo(ta);

    return (a.siswaNama ?? '').toLowerCase().compareTo(
      (b.siswaNama ?? '').toLowerCase(),
    );
  }

  NilaiSummaryEntity _computeSummary(List<NilaiEntity> items) {
    final values = items
        .map((e) => e.nilai)
        .whereType<double>()
        .toList(growable: false);

    double? tertinggi;
    double? terendah;
    double total = 0;
    for (final v in values) {
      total += v;
      if (tertinggi == null || v > tertinggi) tertinggi = v;
      if (terendah == null || v < terendah) terendah = v;
    }

    final computedAvg = values.isEmpty ? null : total / values.length;
    final mapelIds = items.map((e) => e.mapelLabel).toSet();

    // Rata-rata resmi backend hanya valid untuk keseluruhan data siswa;
    // begitu ada filter aktif, hitung ulang dari data yang ditampilkan.
    final noFilter =
        _semester == null && _ujianId == null && _search.trim().isEmpty;

    return NilaiSummaryEntity(
      rataRata: noFilter ? (_rataRataServer ?? computedAvg) : computedAvg,
      jumlahMapel: mapelIds.length,
      tertinggi: tertinggi,
      terendah: terendah,
      total: items.length,
    );
  }

  List<String> _semesterOptions(List<NilaiEntity> items) {
    final set = <String>{};
    for (final e in items) {
      final label = e.semesterLabel;
      if (label != null && label.isNotEmpty) set.add(label);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<NilaiUjianOption> _ujianOptions(List<NilaiEntity> items) {
    final map = <int, NilaiUjianOption>{};
    for (final e in items) {
      final id = e.ujianId;
      if (id == null) continue;
      map.putIfAbsent(
        id,
        () => NilaiUjianOption(
          id: id,
          label: e.judul,
          mapel: e.mapelNama,
          kelas: e.kelasNama,
        ),
      );
    }
    final list = map.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }
}
