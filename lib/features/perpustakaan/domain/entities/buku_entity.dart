import 'package:equatable/equatable.dart';

/// Buku perpustakaan — hasil pemetaan `BukuResource` backend.
///
/// Field backend (terverifikasi di `app/Http/Resources/Api/V1/BukuResource.php`):
/// `id`, `isbn`, `judul`, `penulis`, `penerbit`, `tahun`, `stok`.
///
/// CATATAN PENTING soal [stok]:
/// `PeminjamanBukuService::createPeminjaman()` melakukan `decrement('stok')`
/// dan `pengembalian()` melakukan `increment('stok')`. Jadi kolom `stok`
/// menyimpan **jumlah eksemplar yang sedang tersedia**, bukan total koleksi.
/// Backend tidak mengirim total eksemplar, sehingga teks "3 dari 5 tersedia"
/// hanya bisa dihitung di halaman detail (lewat `/buku/{id}/peminjaman` yang
/// memberi daftar peminjaman aktif).
class BukuEntity extends Equatable {
  final int id;
  final String? isbn;
  final String judul;
  final String? penulis;
  final String? penerbit;
  final int? tahun;

  /// Jumlah eksemplar yang saat ini bisa dipinjam.
  final int stok;

  const BukuEntity({
    required this.id,
    this.isbn,
    required this.judul,
    this.penulis,
    this.penerbit,
    this.tahun,
    this.stok = 0,
  });

  bool get tersedia => stok > 0;

  /// Teks pencarian gabungan (judul + pengarang + penerbit + ISBN).
  String get teksCari =>
      '$judul ${penulis ?? ''} ${penerbit ?? ''} ${isbn ?? ''}'.toLowerCase();

  @override
  List<Object?> get props => [id];
}
