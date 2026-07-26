import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/kelas_option_entity.dart';
import '../../domain/entities/ranking_entity.dart';
import '../../domain/entities/ujian_entity.dart';
import '../../domain/usecases/export_ranking_usecase.dart';
import '../../domain/usecases/generate_ranking_usecase.dart';
import '../../domain/usecases/get_kelas_options_usecase.dart';
import '../../domain/usecases/get_ranking_kelas_usecase.dart';
import '../../domain/usecases/get_ujian_by_kelas_usecase.dart';

part 'ujian_event.dart';
part 'ujian_state.dart';

/// Bloc halaman utama Ujian + Ranking.
///
/// Sumber kelas per role (izin dicek dari permission, bukan role):
/// - siswa      : kelasId dari `profile['kelas']['id']` (dikirim via event).
/// - guru       : pemilih kelas dari `GET /kelas?wali_guru_id={guruId}` —
///                backend (`canAccessKelasId`) hanya mengizinkan guru
///                mengakses kelas yang ia ampu sebagai WALI KELAS, jadi
///                daftar pilihan disaring dengan filter yang sama.
/// - admin      : pemilih kelas dari `GET /kelas` (semua kelas).
/// - wali       : tidak punya `ujian.view` maupun `ranking.view`
///                (RbacSeeder) → halaman menampilkan akses ditolak.
class UjianBloc extends Bloc<UjianEvent, UjianState> {
  final GetUjianByKelasUseCase getUjianByKelas;
  final GetRankingKelasUseCase getRankingKelas;
  final GetKelasOptionsUseCase getKelasOptions;
  final GenerateRankingUseCase generateRanking;
  final ExportRankingUseCase exportRanking;

  String _role = '';
  int? _profileId;
  int? _siswaId;
  int? _kelasId;
  String? _kelasNama;
  bool _canViewUjian = false;
  bool _canViewRanking = false;
  bool _canGenerate = false;
  bool _canExport = false;

  List<KelasOptionEntity> _kelasOptions = const [];
  List<UjianEntity> _ujianItems = const [];
  List<RankingEntity> _rankingItems = const [];
  String? _ujianError;
  String? _rankingError;

  UjianBloc({
    required this.getUjianByKelas,
    required this.getRankingKelas,
    required this.getKelasOptions,
    required this.generateRanking,
    required this.exportRanking,
  }) : super(UjianInitial()) {
    on<UjianLoadRequested>(_onLoad);
    on<UjianKelasChanged>(_onKelasChanged);
    on<UjianRefreshRequested>(_onRefresh);
    on<UjianGenerateRequested>(_onGenerate);
    on<UjianExportRequested>(_onExport);
  }

  bool get _pakaiPemilihKelas => _role != 'siswa' && _role != 'wali';

  Future<void> _onLoad(
    UjianLoadRequested event,
    Emitter<UjianState> emit,
  ) async {
    emit(UjianLoading());

    _role = event.role;
    _profileId = event.profileId;
    _siswaId = event.siswaId;
    _kelasId = event.kelasId;
    _kelasNama = event.kelasNama;
    _canViewUjian = event.canViewUjian;
    _canViewRanking = event.canViewRanking;
    _canGenerate = event.canGenerate;
    _canExport = event.canExport;

    // Tanpa satu pun izin baca, tidak perlu memanggil backend.
    if (!_canViewUjian && !_canViewRanking) {
      emit(_buildLoaded());
      return;
    }

    // Guru/admin: muat daftar kelas untuk pemilih.
    if (_pakaiPemilihKelas) {
      final result = await getKelasOptions(
        waliGuruId: _role == 'guru' ? _profileId : null,
      );
      if (result.isFailure) {
        emit(UjianError(result.requireFailure.message));
        return;
      }
      _kelasOptions = result.requireData;

      // Auto-pilih bila hanya ada satu kelas (kasus umum wali kelas);
      // admin dengan banyak kelas diminta memilih dulu.
      if (_kelasId == null &&
          (_role == 'guru' || _kelasOptions.length == 1) &&
          _kelasOptions.isNotEmpty) {
        _kelasId = _kelasOptions.first.id;
        _kelasNama = _kelasOptions.first.namaKelas;
      }
    }

    await _fetchData();
    emit(_buildLoaded());
  }

  Future<void> _onKelasChanged(
    UjianKelasChanged event,
    Emitter<UjianState> emit,
  ) async {
    _kelasId = event.kelasId;
    _kelasNama = _kelasOptions
        .where((k) => k.id == event.kelasId)
        .map((k) => k.namaKelas)
        .firstOrNull;
    emit(UjianLoading());
    await _fetchData();
    emit(_buildLoaded());
  }

  Future<void> _onRefresh(
    UjianRefreshRequested event,
    Emitter<UjianState> emit,
  ) async {
    if (_role.isEmpty) return;
    if (!_canViewUjian && !_canViewRanking) {
      emit(_buildLoaded());
      return;
    }
    await _fetchData();
    emit(_buildLoaded());
  }

  Future<void> _onGenerate(
    UjianGenerateRequested event,
    Emitter<UjianState> emit,
  ) async {
    final kelasId = _kelasId;
    if (kelasId == null) {
      emit(const UjianActionFailure('Pilih kelas terlebih dahulu'));
      emit(_buildLoaded());
      return;
    }

    emit(_buildLoaded(aksiSedangDiproses: true));
    final result = await generateRanking(
      kelasId: kelasId,
      semesterId: event.semesterId,
      tahunAjaranId: event.tahunAjaranId,
    );

    if (result.isSuccess) {
      _rankingItems = result.requireData;
      _rankingError = null;
      emit(
        UjianActionSuccess(
          'Ranking berhasil digenerate '
          '(${_rankingItems.length} siswa)',
        ),
      );
    } else {
      emit(UjianActionFailure(result.requireFailure.message));
    }
    emit(_buildLoaded());
  }

  Future<void> _onExport(
    UjianExportRequested event,
    Emitter<UjianState> emit,
  ) async {
    final kelasId = _kelasId;
    if (kelasId == null) {
      emit(const UjianActionFailure('Pilih kelas terlebih dahulu'));
      emit(_buildLoaded());
      return;
    }

    emit(_buildLoaded(aksiSedangDiproses: true));
    final result = await exportRanking(
      kelasId: kelasId,
      semesterId: event.semesterId,
      tahunAjaranId: event.tahunAjaranId,
    );

    if (result.isSuccess) {
      emit(
        UjianActionSuccess(
          'Berkas ranking berhasil diunduh',
          filePath: result.requireData,
        ),
      );
    } else {
      emit(UjianActionFailure(result.requireFailure.message));
    }
    emit(_buildLoaded());
  }

  /// Ambil daftar ujian dan ranking secara paralel; error dicatat per tab
  /// agar satu tab gagal tidak menjatuhkan tab lain.
  Future<void> _fetchData() async {
    final kelasId = _kelasId;
    if (kelasId == null) {
      _ujianItems = const [];
      _rankingItems = const [];
      if (_pakaiPemilihKelas) {
        // Belum memilih kelas — bukan error, page menampilkan prompt.
        _ujianError = null;
        _rankingError = null;
      } else {
        const pesan = 'Data kelas tidak ditemukan di profil Anda';
        _ujianError = pesan;
        _rankingError = pesan;
      }
      return;
    }

    // Kedua future dibuat lebih dulu supaya berjalan paralel.
    final ujianFuture = _canViewUjian ? getUjianByKelas(kelasId) : null;
    final rankingFuture = _canViewRanking ? getRankingKelas(kelasId) : null;

    if (ujianFuture != null) {
      final result = await ujianFuture;
      if (result.isSuccess) {
        _ujianItems = result.requireData;
        _ujianError = null;
      } else {
        _ujianItems = const [];
        _ujianError = result.requireFailure.message;
      }
    }
    if (rankingFuture != null) {
      final result = await rankingFuture;
      if (result.isSuccess) {
        _rankingItems = result.requireData;
        _rankingError = null;
      } else {
        _rankingItems = const [];
        _rankingError = result.requireFailure.message;
      }
    }
  }

  UjianLoaded _buildLoaded({bool aksiSedangDiproses = false}) => UjianLoaded(
    role: _role,
    kelasId: _kelasId,
    kelasNama: _kelasNama,
    kelasOptions: _kelasOptions,
    ujianItems: _ujianItems,
    ujianError: _ujianError,
    rankingItems: _rankingItems,
    rankingError: _rankingError,
    siswaId: _siswaId,
    canViewUjian: _canViewUjian,
    canViewRanking: _canViewRanking,
    canGenerate: _canGenerate,
    canExport: _canExport,
    aksiSedangDiproses: aksiSedangDiproses,
  );
}
