import '../../../../core/error/result.dart';
import '../entities/buku_entity.dart';
import '../entities/buku_riwayat_entity.dart';
import '../entities/peminjaman_buku_entity.dart';

abstract class PerpustakaanRepository {
  /// Katalog buku — `GET /perpustakaan/buku`.
  ///
  /// [search] diteruskan ke backend; `BukuService::getAllBuku()` benar-benar
  /// menerapkannya pada `judul`, `isbn`, dan `penulis` (bukan hanya jalur
  /// AG-Grid). Tetap opsional karena UI menyaring di client.
  Future<Result<List<BukuEntity>>> getBukuList({int perPage, String? search});

  /// Buku dengan `stok > 0` — `GET /perpustakaan/buku/available`.
  Future<Result<List<BukuEntity>>> getBukuAvailable();

  /// Detail satu buku — `GET /perpustakaan/buku/{id}`.
  Future<Result<BukuEntity>> getBukuDetail(int bukuId);

  /// Peminjaman aktif untuk satu buku — `GET /perpustakaan/buku/{id}/peminjaman`.
  Future<Result<BukuRiwayatEntity>> getRiwayatBuku(int bukuId);

  /// Daftar peminjaman umum — `GET /perpustakaan/peminjaman`.
  /// Backend sudah memfilter per sesi (siswa → dirinya, guru → kelas walinya,
  /// wali → anak-anaknya, admin → semua).
  Future<Result<List<PeminjamanBukuEntity>>> getPeminjamanList({int perPage});

  /// Peminjaman milik satu siswa — `GET /perpustakaan/peminjaman/siswa/{id}`.
  Future<Result<List<PeminjamanBukuEntity>>> getPeminjamanBySiswa(int siswaId);

  /// Peminjaman terlambat — `GET /perpustakaan/peminjaman/overdue`.
  Future<Result<List<PeminjamanBukuEntity>>> getPeminjamanOverdue();

  /// Buat peminjaman — `POST /perpustakaan/peminjaman`
  /// (butuh permission `peminjaman.create`).
  Future<Result<PeminjamanBukuEntity>> createPeminjaman({
    required int siswaId,
    required int bukuId,
    String? tanggalPinjam,
    required String tanggalJatuhTempo,
  });

  /// Proses pengembalian — `POST /perpustakaan/peminjaman/{id}/pengembalian`
  /// (butuh permission `peminjaman.pengembalian`).
  Future<Result<PeminjamanBukuEntity>> prosesPengembalian(int peminjamanId);
}
