part of 'ekstrakurikuler_bloc.dart';

abstract class EkstrakurikulerState extends Equatable {
  const EkstrakurikulerState();
  @override
  List<Object?> get props => [];
}

class EkstrakurikulerInitial extends EkstrakurikulerState {}

class EkstrakurikulerLoading extends EkstrakurikulerState {}

class EkstrakurikulerLoaded extends EkstrakurikulerState {
  /// Tab "Semua Ekskul" (sudah disaring kata kunci pencarian).
  final List<EkstrakurikulerEntity> semua;

  /// Keanggotaan berstatus aktif milik siswa / anak wali.
  final List<PendaftaranEkskulEntity> keanggotaan;

  /// Riwayat pendaftaran (semua status), terurut tanggal daftar terbaru.
  final List<PendaftaranEkskulEntity> riwayat;

  /// Ekskul yang dibina guru yang sedang login.
  final List<EkstrakurikulerEntity> dibina;

  final EkskulSumber sumber;
  final String search;
  final String role;
  final int? siswaId;
  final int? guruId;
  final bool canManagePendaftaran;
  final bool canViewPendaftaran;

  /// Pesan kendala khusus tab "Ekskul Saya" (izin kurang / gagal muat).
  final String? pesanTabSaya;

  const EkstrakurikulerLoaded({
    required this.semua,
    required this.keanggotaan,
    required this.riwayat,
    required this.dibina,
    required this.sumber,
    required this.search,
    required this.role,
    this.siswaId,
    this.guruId,
    this.canManagePendaftaran = false,
    this.canViewPendaftaran = false,
    this.pesanTabSaya,
  });

  bool get isSiswaMode => role == 'siswa';
  bool get isGuruMode => role == 'guru';
  bool get isWaliMode => role == 'wali';

  /// Untuk wali backend tidak menyediakan id siswa di profil, sehingga tab
  /// "Ekskul Saya" bergantung pada endpoint index yang sudah difilter sesi.
  bool get waliTanpaSiswaId => isWaliMode && siswaId == null;

  /// Id ekskul yang sedang diikuti (status `aktif`).
  Set<int> get idTerdaftar => keanggotaan
      .where((e) => e.isAktif)
      .map((e) => e.ekstrakurikulerId)
      .whereType<int>()
      .toSet();

  bool sudahTerdaftar(int ekstrakurikulerId) =>
      idTerdaftar.contains(ekstrakurikulerId);

  /// Hanya siswa dengan id profil + izin manage yang boleh mendaftar.
  bool get bolehMendaftar =>
      isSiswaMode && siswaId != null && canManagePendaftaran;

  bool bisaDaftar(int ekstrakurikulerId) =>
      bolehMendaftar && !sudahTerdaftar(ekstrakurikulerId);

  /// Keluar ekskul memakai permission yang sama dengan mendaftar.
  bool get bolehKeluar => canManagePendaftaran;

  /// Riwayat yang statusnya bukan aktif (sudah keluar).
  List<PendaftaranEkskulEntity> get riwayatKeluar =>
      riwayat.where((e) => !e.isAktif).toList();

  @override
  List<Object?> get props => [
    semua,
    keanggotaan,
    riwayat,
    dibina,
    sumber,
    search,
    role,
    siswaId,
    guruId,
    canManagePendaftaran,
    canViewPendaftaran,
    pesanTabSaya,
  ];
}

class EkstrakurikulerError extends EkstrakurikulerState {
  final String message;
  const EkstrakurikulerError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk SnackBar setelah aksi berhasil.
class EkstrakurikulerActionSuccess extends EkstrakurikulerState {
  final String message;
  const EkstrakurikulerActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk SnackBar setelah aksi gagal.
class EkstrakurikulerActionFailure extends EkstrakurikulerState {
  final String message;
  const EkstrakurikulerActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
