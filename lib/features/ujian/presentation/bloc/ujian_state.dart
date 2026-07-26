part of 'ujian_bloc.dart';

abstract class UjianState extends Equatable {
  const UjianState();
  @override
  List<Object?> get props => [];
}

class UjianInitial extends UjianState {}

class UjianLoading extends UjianState {}

class UjianLoaded extends UjianState {
  final String role;
  final int? kelasId;
  final String? kelasNama;
  final List<KelasOptionEntity> kelasOptions;

  final List<UjianEntity> ujianItems;

  /// Error khusus tab Ujian (null = tidak ada error).
  final String? ujianError;

  final List<RankingEntity> rankingItems;

  /// Error khusus tab Ranking.
  final String? rankingError;

  /// Id siswa login (untuk sorot baris miliknya di papan ranking).
  final int? siswaId;

  final bool canViewUjian;
  final bool canViewRanking;
  final bool canGenerate;
  final bool canExport;

  /// True selama generate/export ranking berlangsung.
  final bool aksiSedangDiproses;

  const UjianLoaded({
    required this.role,
    this.kelasId,
    this.kelasNama,
    this.kelasOptions = const [],
    this.ujianItems = const [],
    this.ujianError,
    this.rankingItems = const [],
    this.rankingError,
    this.siswaId,
    this.canViewUjian = false,
    this.canViewRanking = false,
    this.canGenerate = false,
    this.canExport = false,
    this.aksiSedangDiproses = false,
  });

  bool get pakaiPemilihKelas => role != 'siswa' && role != 'wali';

  /// Kelas terpilih pada pemilih (null bila belum memilih / role siswa).
  KelasOptionEntity? get kelasTerpilih =>
      kelasOptions.where((k) => k.id == kelasId).firstOrNull;

  /// Prefill id mst_semester untuk form generate/export:
  /// dari baris ranking yang ada, fallback dari daftar ujian.
  int? get prefillSemesterId {
    for (final r in rankingItems) {
      if (r.semesterId != null) return r.semesterId;
    }
    for (final u in ujianItems) {
      if (u.semesterId != null) return u.semesterId;
    }
    return null;
  }

  /// Prefill id mst_tahun_ajaran dari kelas terpilih.
  int? get prefillTahunAjaranId => kelasTerpilih?.tahunAjaranId;

  @override
  List<Object?> get props => [
    role,
    kelasId,
    kelasNama,
    kelasOptions,
    ujianItems,
    ujianError,
    rankingItems,
    rankingError,
    siswaId,
    canViewUjian,
    canViewRanking,
    canGenerate,
    canExport,
    aksiSedangDiproses,
  ];
}

class UjianError extends UjianState {
  final String message;
  const UjianError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk snackbar (generate/export selesai).
/// [filePath] terisi untuk hasil export → dibuka dengan open_filex.
class UjianActionSuccess extends UjianState {
  final String message;
  final String? filePath;
  const UjianActionSuccess(this.message, {this.filePath});

  @override
  List<Object?> get props => [message, filePath];
}

class UjianActionFailure extends UjianState {
  final String message;
  const UjianActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
