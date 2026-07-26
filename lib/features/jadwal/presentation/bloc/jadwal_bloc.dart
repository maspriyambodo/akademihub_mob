import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/jadwal_pelajaran_entity.dart';
import '../../domain/usecases/get_jadwal_kelas_usecase.dart';
import '../../domain/usecases/get_jadwal_list_usecase.dart';

part 'jadwal_event.dart';
part 'jadwal_state.dart';

class JadwalBloc extends Bloc<JadwalEvent, JadwalState> {
  final GetJadwalKelasUseCase getJadwalKelas;
  final GetJadwalKelasHariUseCase getJadwalKelasHari;
  final GetJadwalListUseCase getJadwalList;

  /// Cache seluruh jadwal satu minggu; tab hari difilter dari sini.
  List<JadwalPelajaranEntity> _all = [];
  String _role = '';
  int? _kelasId;
  int? _guruId;
  String _selectedHari = hariCodeFromWeekday(DateTime.now().weekday);

  JadwalBloc({
    required this.getJadwalKelas,
    required this.getJadwalKelasHari,
    required this.getJadwalList,
  }) : super(JadwalInitial()) {
    on<JadwalLoadRequested>(_onLoad);
    on<JadwalHariChanged>(_onHariChanged);
    on<JadwalRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    JadwalLoadRequested event,
    Emitter<JadwalState> emit,
  ) async {
    _role = event.role;
    _kelasId = event.kelasId;
    _guruId = event.guruId;
    _selectedHari = _normalizeHari(event.hari);
    _all = [];
    emit(JadwalLoading());
    await _fetchAll(emit);
  }

  void _onHariChanged(JadwalHariChanged event, Emitter<JadwalState> emit) {
    _selectedHari = event.hari.toUpperCase();
    if (state is JadwalLoaded) {
      emit(_buildLoaded());
    }
  }

  Future<void> _onRefresh(
    JadwalRefreshRequested event,
    Emitter<JadwalState> emit,
  ) async {
    // Untuk siswa/wali (punya kelasId) dan data sudah ada: cukup segarkan
    // hari yang sedang dilihat lewat endpoint per-hari, lebih ringan.
    if (_kelasId != null && _all.isNotEmpty) {
      final result = await getJadwalKelasHari(_kelasId!, _selectedHari);
      if (result.isSuccess) {
        final segar = result.requireData;
        _all = [
          ..._all.where((e) => e.hari != _selectedHari),
          ...segar,
        ];
        emit(_buildLoaded());
      } else {
        emit(JadwalError(result.requireFailure.message));
      }
      return;
    }

    _all = [];
    emit(JadwalLoading());
    await _fetchAll(emit);
  }

  Future<void> _fetchAll(Emitter<JadwalState> emit) async {
    // siswa / wali → jadwal kelasnya sendiri
    if (_kelasId != null) {
      final result = await getJadwalKelas(_kelasId!);
      if (result.isSuccess) {
        _all = result.requireData;
        emit(_buildLoaded());
      } else {
        emit(JadwalError(result.requireFailure.message));
      }
      return;
    }

    if (_role == 'siswa' || _role == 'wali') {
      emit(
        const JadwalError(
          'Data kelas tidak tersedia pada profil Anda. '
          'Hubungi admin sekolah untuk melengkapi data kelas.',
        ),
      );
      return;
    }

    // guru & admin → endpoint index (`per_page=all`).
    // Backend tidak punya endpoint jadwal per-guru dan filter index hanya
    // mengenal kelas_id / guru_mapel_id / hari — sedangkan yang kita punya
    // adalah guru id. Jadi penyaringan milik guru dilakukan di client
    // berdasarkan `guru_mapel.guru.id`.
    final result = await getJadwalList();
    if (result.isSuccess) {
      final data = result.requireData;
      _all = (_role == 'guru' && _guruId != null)
          ? data.where((e) => e.guruId == _guruId).toList()
          : data;
      emit(_buildLoaded());
    } else {
      emit(JadwalError(result.requireFailure.message));
    }
  }

  JadwalLoaded _buildLoaded() {
    final now = DateTime.now();
    final available = _availableHari();
    final selected = available.contains(_selectedHari)
        ? _selectedHari
        : (available.isNotEmpty ? available.first : _selectedHari);
    _selectedHari = selected;

    final items = _all.where((e) => e.hari == selected).toList()
      ..sort((a, b) {
        final am = a.mulaiMenit ?? 24 * 60;
        final bm = b.mulaiMenit ?? 24 * 60;
        if (am != bm) return am.compareTo(bm);
        return (a.mapelNama ?? '').compareTo(b.mapelNama ?? '');
      });

    return JadwalLoaded(
      role: _role,
      selectedHari: selected,
      availableHari: available,
      items: items,
      totalMinggu: _all.length,
      now: now,
    );
  }

  /// Senin–Sabtu selalu tampil; Minggu hanya bila memang ada jadwalnya.
  List<String> _availableHari() {
    final hasMinggu = _all.any((e) => e.hari == 'SUN');
    return hasMinggu ? const [...kHariKerjaCodes, 'SUN'] : kHariKerjaCodes;
  }

  /// Default ke hari ini. Bila hari tersebut ternyata tidak tersedia sebagai
  /// tab (mis. Minggu tanpa jadwal), `_buildLoaded` akan jatuh ke hari pertama.
  String _normalizeHari(String? hari) {
    if (hari != null && hari.isNotEmpty) return hari.toUpperCase();
    return hariCodeFromWeekday(DateTime.now().weekday);
  }
}
