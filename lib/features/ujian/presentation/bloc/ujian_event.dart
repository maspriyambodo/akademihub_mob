part of 'ujian_bloc.dart';

abstract class UjianEvent extends Equatable {
  const UjianEvent();
  @override
  List<Object?> get props => [];
}

/// Muat awal. [kelasId] hanya diisi untuk role siswa
/// (dari `profile['kelas']['id']`); guru/admin memakai pemilih kelas.
class UjianLoadRequested extends UjianEvent {
  final String role;
  final int? profileId;

  /// Id siswa yang sedang login (untuk sorot baris miliknya di ranking).
  final int? siswaId;
  final int? kelasId;
  final String? kelasNama;
  final bool canViewUjian;
  final bool canViewRanking;
  final bool canGenerate;
  final bool canExport;

  const UjianLoadRequested({
    required this.role,
    this.profileId,
    this.siswaId,
    this.kelasId,
    this.kelasNama,
    this.canViewUjian = false,
    this.canViewRanking = false,
    this.canGenerate = false,
    this.canExport = false,
  });

  @override
  List<Object?> get props => [
    role,
    profileId,
    siswaId,
    kelasId,
    kelasNama,
    canViewUjian,
    canViewRanking,
    canGenerate,
    canExport,
  ];
}

/// Guru/admin memilih kelas lain dari pemilih kelas.
class UjianKelasChanged extends UjianEvent {
  final int kelasId;
  const UjianKelasChanged(this.kelasId);

  @override
  List<Object?> get props => [kelasId];
}

class UjianRefreshRequested extends UjianEvent {
  const UjianRefreshRequested();
}

/// Generate ranking kelas terpilih (permission `ranking.generate`).
/// [semesterId] = id `mst_semester`, [tahunAjaranId] = id `mst_tahun_ajaran`.
class UjianGenerateRequested extends UjianEvent {
  final int semesterId;
  final int tahunAjaranId;

  const UjianGenerateRequested({
    required this.semesterId,
    required this.tahunAjaranId,
  });

  @override
  List<Object?> get props => [semesterId, tahunAjaranId];
}

/// Unduh xlsx ranking kelas terpilih (permission `ranking.export`).
class UjianExportRequested extends UjianEvent {
  final int semesterId;
  final int tahunAjaranId;

  const UjianExportRequested({
    required this.semesterId,
    required this.tahunAjaranId,
  });

  @override
  List<Object?> get props => [semesterId, tahunAjaranId];
}
