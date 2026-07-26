import 'package:equatable/equatable.dart';

/// Satu baris peminjaman aktif pada endpoint
/// `GET /perpustakaan/buku/{id}/peminjaman`.
///
/// Bentuk data dibangun manual di `BukuService::getPeminjamanByBuku()`
/// (bukan lewat Resource), berisi: `id`, `siswa{id,nama,nis}`,
/// `tanggal_pinjam` (Carbon mentah → ISO 8601).
class PeminjamanAktifEntity extends Equatable {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final String? tanggalPinjam;

  const PeminjamanAktifEntity({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.tanggalPinjam,
  });

  DateTime? get tanggalPinjamDate =>
      tanggalPinjam == null ? null : DateTime.tryParse(tanggalPinjam!);

  @override
  List<Object?> get props => [id];
}

/// Ringkasan peminjaman satu buku.
///
/// Hanya peminjaman yang belum dikembalikan (`tanggal_kembali IS NULL`) yang
/// dikirim backend, jadi ini bukan riwayat penuh melainkan daftar eksemplar
/// yang sedang dipegang siswa.
class BukuRiwayatEntity extends Equatable {
  final int bukuId;
  final String? judul;

  /// Sisa eksemplar yang bisa dipinjam saat ini.
  final int stok;

  final List<PeminjamanAktifEntity> peminjamanAktif;

  const BukuRiwayatEntity({
    required this.bukuId,
    this.judul,
    this.stok = 0,
    this.peminjamanAktif = const [],
  });

  /// Total eksemplar = sisa stok + yang sedang dipinjam.
  int get totalEksemplar => stok + peminjamanAktif.length;

  @override
  List<Object?> get props => [bukuId, stok, peminjamanAktif];
}
