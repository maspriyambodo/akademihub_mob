part of 'perpustakaan_bloc.dart';

abstract class PerpustakaanState extends Equatable {
  const PerpustakaanState();
  @override
  List<Object?> get props => [];
}

class PerpustakaanInitial extends PerpustakaanState {}

class PerpustakaanLoading extends PerpustakaanState {}

class PerpustakaanLoaded extends PerpustakaanState {
  /// Buku setelah filter pencarian + "hanya yang tersedia".
  final List<BukuEntity> buku;

  /// Jumlah buku sebelum difilter (untuk pesan kosong yang tepat).
  final int totalBuku;

  /// Pesan error khusus tab Katalog (tab lain tetap bisa dipakai).
  final String? bukuError;

  final List<PeminjamanBukuEntity> peminjaman;

  /// Pesan error khusus tab Peminjaman.
  final String? peminjamanError;

  /// Id peminjaman yang ditandai terlambat oleh endpoint `/overdue`.
  final Set<int> overdueIds;

  final String searchQuery;
  final bool hanyaTersedia;

  final String role;
  final int? siswaId;

  final bool canCreate;
  final bool canPengembalian;
  final bool canLihatRiwayat;

  /// Sedang memproses aksi tulis (pinjam / pengembalian).
  final bool aksiSedangDiproses;

  const PerpustakaanLoaded({
    required this.buku,
    required this.totalBuku,
    this.bukuError,
    required this.peminjaman,
    this.peminjamanError,
    this.overdueIds = const <int>{},
    this.searchQuery = '',
    this.hanyaTersedia = false,
    required this.role,
    this.siswaId,
    this.canCreate = false,
    this.canPengembalian = false,
    this.canLihatRiwayat = false,
    this.aksiSedangDiproses = false,
  });

  bool get isSiswaMode => role == 'siswa';
  bool get isWaliMode => role == 'wali';
  bool get isGuruMode => role == 'guru';

  /// Label tab kedua menyesuaikan role.
  String get labelTabPeminjaman => switch (role) {
    'siswa' => 'Peminjaman Saya',
    'wali' => 'Peminjaman Anak',
    'guru' => 'Peminjaman Siswa',
    _ => 'Peminjaman',
  };

  /// Terlambat bila perhitungan lokal ATAU endpoint `/overdue` bilang begitu.
  bool terlambat(PeminjamanBukuEntity item) =>
      item.terlambat ||
      (!item.sudahDikembalikan && overdueIds.contains(item.id));

  int get jumlahTerlambat => peminjaman.where(terlambat).length;

  int get jumlahAktif =>
      peminjaman.where((e) => !e.sudahDikembalikan && !e.hilang).length;

  @override
  List<Object?> get props => [
    buku,
    totalBuku,
    bukuError,
    peminjaman,
    peminjamanError,
    overdueIds,
    searchQuery,
    hanyaTersedia,
    role,
    siswaId,
    canCreate,
    canPengembalian,
    canLihatRiwayat,
    aksiSedangDiproses,
  ];
}

/// Gagal total — kedua tab tidak punya data sama sekali.
class PerpustakaanError extends PerpustakaanState {
  final String message;
  const PerpustakaanError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk SnackBar sukses.
class PerpustakaanActionSuccess extends PerpustakaanState {
  final String message;
  const PerpustakaanActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk SnackBar gagal.
class PerpustakaanActionFailure extends PerpustakaanState {
  final String message;
  const PerpustakaanActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
