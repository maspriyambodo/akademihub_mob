import 'package:equatable/equatable.dart';

/// Kasus Bimbingan Konseling (`trx_bk_kasus`).
///
/// Catatan verifikasi backend (`BkKasusResource`):
/// - `siswa` hanya dimuat pada endpoint index (`/bk/kasus`), TIDAK pada
///   `/bk/kasus/siswa/{id}` — jadi [siswaNama] bisa null untuk role siswa.
/// - `status` sudah berupa label dari `sys_references` grup `status_bk`
///   (dibuka/proses/selesai/dirujuk) atau angka mentah bila referensi hilang.
/// - `tanggal` & `keterangan` saat ini selalu null karena resource membaca
///   atribut yang tidak ada di tabel (kolom aslinya `tanggal_mulai` dan
///   `deskripsi_masalah`); model tetap mem-parsing kedua nama kolom agar
///   otomatis terisi bila backend diperbaiki.
class BkKasusEntity extends Equatable {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final int? guruId;
  final String? guruNama;
  final int? jenisId;
  final String? jenisKode;
  final String? jenisNama;
  final String? judul;
  final String? tanggal; // yyyy-MM-dd
  final String? keterangan;
  final String? status;
  final String? createdAt; // ISO 8601

  const BkKasusEntity({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.guruId,
    this.guruNama,
    this.jenisId,
    this.jenisKode,
    this.jenisNama,
    this.judul,
    this.tanggal,
    this.keterangan,
    this.status,
    this.createdAt,
  });

  /// Tanggal terbaik yang tersedia untuk ditampilkan/diurutkan.
  DateTime? get tanggalDate {
    final t = tanggal;
    if (t != null && t.isNotEmpty) return DateTime.tryParse(t);
    final c = createdAt;
    if (c != null && c.isNotEmpty) return DateTime.tryParse(c);
    return null;
  }

  String get statusLabel {
    final s = (status ?? '').trim();
    if (s.isEmpty) return 'Tidak diketahui';
    // Fallback bila referensi label hilang dan backend mengirim angka mentah.
    switch (s) {
      case '1':
        return 'dibuka';
      case '2':
        return 'proses';
      case '3':
        return 'selesai';
      case '4':
        return 'dirujuk';
    }
    return s;
  }

  @override
  List<Object?> get props => [id];
}
