import 'package:equatable/equatable.dart';

/// Status peminjaman yang dipakai UI.
enum StatusPeminjaman { dipinjam, dikembalikan, hilang }

/// Peminjaman buku — hasil pemetaan `PeminjamanBukuResource` backend.
///
/// Field backend (terverifikasi di
/// `app/Http/Resources/Api/V1/PeminjamanBukuResource.php`):
/// `id`, `siswa{id,nama,nis}`, `buku{id,judul,isbn}`, `tanggal_pinjam`,
/// `tanggal_jatuh_tempo`, `tanggal_kembali` (semua format `YYYY-MM-DD`),
/// `status` (LABEL string dari `sys_references.status_pinjam`:
/// `dipinjam` / `dikembalikan` / `hilang`), `keterangan`.
///
/// CATATAN: `PeminjamanBukuService::pengembalian()` HANYA mengisi
/// `tanggal_kembali` dan tidak pernah mengubah kolom `status`. Akibatnya buku
/// yang sudah dikembalikan tetap berlabel `dipinjam`. Karena itu status yang
/// dipakai UI diturunkan dari `tanggal_kembali` — lihat [statusEfektif].
class PeminjamanBukuEntity extends Equatable {
  final int id;

  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;

  final int? bukuId;
  final String? bukuJudul;
  final String? bukuIsbn;

  /// Format `YYYY-MM-DD`.
  final String? tanggalPinjam;
  final String? tanggalJatuhTempo;
  final String? tanggalKembali;

  /// Label mentah dari backend (bisa tidak akurat, lihat catatan kelas).
  final String? status;

  /// Selalu `null` pada API saat ini — kolom `keterangan` tidak ada di
  /// migrasi `trx_peminjaman_buku` walaupun Resource ikut mengirimkannya.
  final String? keterangan;

  const PeminjamanBukuEntity({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.bukuId,
    this.bukuJudul,
    this.bukuIsbn,
    this.tanggalPinjam,
    this.tanggalJatuhTempo,
    this.tanggalKembali,
    this.status,
    this.keterangan,
  });

  DateTime? get tanggalPinjamDate => _parse(tanggalPinjam);
  DateTime? get tanggalJatuhTempoDate => _parse(tanggalJatuhTempo);
  DateTime? get tanggalKembaliDate => _parse(tanggalKembali);

  bool get sudahDikembalikan => tanggalKembaliDate != null;

  bool get hilang => (status ?? '').toLowerCase().contains('hilang');

  /// Status yang benar-benar dipakai UI.
  StatusPeminjaman get statusEfektif {
    if (hilang) return StatusPeminjaman.hilang;
    if (sudahDikembalikan) return StatusPeminjaman.dikembalikan;
    return StatusPeminjaman.dipinjam;
  }

  String get statusLabel => switch (statusEfektif) {
    StatusPeminjaman.dipinjam => 'Dipinjam',
    StatusPeminjaman.dikembalikan => 'Dikembalikan',
    StatusPeminjaman.hilang => 'Hilang',
  };

  /// Sisa hari sampai jatuh tempo dihitung dari hari ini.
  /// Nilai negatif berarti sudah lewat. `null` bila jatuh tempo tidak diisi
  /// (kolom `tanggal_jatuh_tempo` nullable di database).
  int? get sisaHari {
    final jatuhTempo = tanggalJatuhTempoDate;
    if (jatuhTempo == null) return null;
    return _selisihHari(DateTime.now(), jatuhTempo);
  }

  /// Terlambat = belum dikembalikan DAN jatuh tempo sudah lewat.
  bool get terlambat {
    if (sudahDikembalikan || hilang) return false;
    final sisa = sisaHari;
    return sisa != null && sisa < 0;
  }

  /// Jumlah hari keterlambatan (0 bila tidak terlambat).
  int get hariTerlambat {
    final sisa = sisaHari;
    if (!terlambat || sisa == null) return 0;
    return -sisa;
  }

  /// Dikembalikan setelah jatuh tempo (informasi historis).
  bool get dikembalikanTerlambat {
    final kembali = tanggalKembaliDate;
    final jatuhTempo = tanggalJatuhTempoDate;
    if (kembali == null || jatuhTempo == null) return false;
    return _selisihHari(jatuhTempo, kembali) > 0;
  }

  static DateTime? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Selisih hari kalender (mengabaikan komponen jam).
  static int _selisihHari(DateTime dari, DateTime sampai) {
    final a = DateTime(dari.year, dari.month, dari.day);
    final b = DateTime(sampai.year, sampai.month, sampai.day);
    return b.difference(a).inDays;
  }

  @override
  List<Object?> get props => [id];
}
