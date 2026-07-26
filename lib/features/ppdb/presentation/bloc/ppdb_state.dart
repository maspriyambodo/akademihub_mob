part of 'ppdb_bloc.dart';

abstract class PpdbState extends Equatable {
  const PpdbState();

  @override
  List<Object?> get props => [];
}

class PpdbInitial extends PpdbState {}

class PpdbLoading extends PpdbState {}

/// User tidak punya permission `ppdb.pendaftaran.view`.
class PpdbForbidden extends PpdbState {
  final String message;
  const PpdbForbidden(this.message);

  @override
  List<Object?> get props => [message];
}

class PpdbError extends PpdbState {
  final String message;
  const PpdbError(this.message);

  @override
  List<Object?> get props => [message];
}

class PpdbLoaded extends PpdbState {
  final PpdbStatistikEntity statistik;
  final List<PpdbGelombangEntity> gelombangList;
  final PpdbGelombangEntity? gelombangAktif;
  final List<PpdbPendaftarEntity> pendaftarList;
  final String search;
  final String? filterStatus;
  final int? filterGelombangId;

  /// `true` saat daftar sedang dimuat ulang akibat perubahan search/filter
  /// (kartu ringkasan tetap tampil, daftar menampilkan indikator).
  final bool sedangMemuatDaftar;

  /// Versi permintaan yang menghasilkan state ini. Entity membandingkan
  /// dirinya hanya lewat `id` (pola proyek), sehingga tanpa versi ini dua
  /// Loaded berturut-turut bisa dianggap sama walau isi field berubah.
  final int versi;

  const PpdbLoaded({
    required this.statistik,
    required this.gelombangList,
    this.gelombangAktif,
    required this.pendaftarList,
    this.search = '',
    this.filterStatus,
    this.filterGelombangId,
    this.sedangMemuatDaftar = false,
    this.versi = 0,
  });

  bool get adaFilterAktif =>
      search.isNotEmpty || filterStatus != null || filterGelombangId != null;

  @override
  List<Object?> get props => [
    statistik,
    gelombangList,
    gelombangAktif,
    pendaftarList,
    search,
    filterStatus,
    filterGelombangId,
    sedangMemuatDaftar,
    versi,
  ];
}
