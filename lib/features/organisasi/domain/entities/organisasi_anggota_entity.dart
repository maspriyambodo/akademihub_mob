import 'package:equatable/equatable.dart';

/// Entity anggota organisasi (tabel `trx_organisasi_anggota`).
///
/// Diambil dari `GET /organisasi/{id}` — backend mengirim serialisasi model
/// Eloquent dengan relasi `jabatan` (`mst_organisasi_jabatan`) dan `siswa`
/// (`mst_siswa`) ter-load. Kolom sebenarnya (verifikasi migrasi
/// `create_trx_organisasi_anggota_table`): `status` smallint
/// (0=nonaktif, 1=aktif, 2=alumni), `tanggal_masuk`, `tanggal_keluar`,
/// `keterangan`.
///
/// Catatan: relasi kelas siswa TIDAK ikut ter-load backend, jadi yang
/// ditampilkan sebagai identitas tambahan adalah NIS.
class OrganisasiAnggotaEntity extends Equatable {
  final int id;
  final int? organisasiId;
  final int? siswaId;

  final String siswaNama;
  final String? siswaNis;

  final int? jabatanId;

  /// Nama jabatan, mis. `Ketua`, `Sekretaris`. Null bila anggota biasa
  /// tanpa jabatan (kolom `jabatan_id` nullable).
  final String? jabatanNama;

  /// Urutan hierarki jabatan (kolom `urutan`, kecil = lebih tinggi).
  final int? jabatanUrutan;

  /// 0 = nonaktif, 1 = aktif, 2 = alumni.
  final int status;

  final DateTime? tanggalMasuk;
  final DateTime? tanggalKeluar;
  final String? keterangan;

  const OrganisasiAnggotaEntity({
    required this.id,
    this.organisasiId,
    this.siswaId,
    required this.siswaNama,
    this.siswaNis,
    this.jabatanId,
    this.jabatanNama,
    this.jabatanUrutan,
    this.status = 1,
    this.tanggalMasuk,
    this.tanggalKeluar,
    this.keterangan,
  });

  bool get isAktif => status == 1;
  bool get isAlumni => status == 2;

  String get statusLabel => switch (status) {
    1 => 'Aktif',
    2 => 'Alumni',
    _ => 'Nonaktif',
  };

  /// Inisial nama untuk avatar, maks 2 huruf: `Budi Santoso` → `BS`.
  String get inisial {
    final kata = siswaNama
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();
    if (kata.isEmpty) return '?';
    if (kata.length == 1) {
      return kata.first.substring(0, 1).toUpperCase();
    }
    return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
  }

  static const List<String> _namaBulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String _formatTanggal(DateTime t) =>
      '${t.day} ${_namaBulan[t.month - 1]} ${t.year}';

  /// Label masa keanggotaan: `12 Jan 2024 - 10 Feb 2025`,
  /// `Sejak 12 Jan 2024`, atau null bila tanggal masuk tidak ada.
  String? get masaKeanggotaanLabel {
    final masuk = tanggalMasuk;
    if (masuk == null) return null;
    final keluar = tanggalKeluar;
    if (keluar == null) return 'Sejak ${_formatTanggal(masuk)}';
    return '${_formatTanggal(masuk)} - ${_formatTanggal(keluar)}';
  }

  @override
  List<Object?> get props => [id];
}
