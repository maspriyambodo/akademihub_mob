import 'package:equatable/equatable.dart';

import 'ppdb_dokumen_entity.dart';

/// Status pendaftaran yang valid di backend
/// (`PpdbPendaftaranService::updateStatus`).
const List<String> kPpdbStatusPendaftaran = [
  'draft',
  'terverifikasi',
  'seleksi',
  'diterima',
  'cadangan',
  'ditolak',
];

/// Pendaftar PPDB.
///
/// Sumber: tabel `ppdb_pendaftar` via `PpdbPendaftaranResource`
/// (endpoint `/ppdb/pendaftaran`).
class PpdbPendaftarEntity extends Equatable {
  final int id;
  final int? sekolahId;
  final int? gelombangId;
  final String noPendaftaran;
  final String namaLengkap;
  final String? email;
  final String? nisn;

  /// 1 = Laki-laki, 2 = Perempuan (referensi `sys_references`).
  final int? jenisKelamin;
  final String? jenisKelaminLabel;
  final String? telpHp;
  final String? asalSekolah;

  /// `draft` | `terverifikasi` | `seleksi` | `diterima` | `cadangan` |
  /// `ditolak`.
  final String statusPendaftaran;

  /// Format `Y-m-d`.
  final String? tanggalLahir;
  final int? usia;
  final int? jumlahPrestasi;
  final String? tingkatPrestasiTertinggi;
  final int? poinPelanggaran;
  final bool isHafidz;
  final int? juzHafalan;

  /// Rata-rata nilai rapor (dihitung backend dari tabel 3NF).
  final double? nilaiRataRata;

  final String? namaGelombang;
  final String? namaSekolah;

  /// Dokumen ringkas yang menempel di response detail
  /// (`id`, `jenis_dokumen`, `file_name`, `verifikasi_status`).
  final List<PpdbDokumenEntity> dokumens;

  final bool isSuspectFraud;
  final String? fraudReason;

  /// ISO 8601.
  final String? createdAt;

  const PpdbPendaftarEntity({
    required this.id,
    this.sekolahId,
    this.gelombangId,
    this.noPendaftaran = '',
    this.namaLengkap = '',
    this.email,
    this.nisn,
    this.jenisKelamin,
    this.jenisKelaminLabel,
    this.telpHp,
    this.asalSekolah,
    this.statusPendaftaran = 'draft',
    this.tanggalLahir,
    this.usia,
    this.jumlahPrestasi,
    this.tingkatPrestasiTertinggi,
    this.poinPelanggaran,
    this.isHafidz = false,
    this.juzHafalan,
    this.nilaiRataRata,
    this.namaGelombang,
    this.namaSekolah,
    this.dokumens = const [],
    this.isSuspectFraud = false,
    this.fraudReason,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
