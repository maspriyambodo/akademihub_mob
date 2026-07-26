import '../../domain/entities/ppdb_pendaftar_entity.dart';
import 'ppdb_dokumen_model.dart';
import 'ppdb_parse_utils.dart';

/// Model pendaftar PPDB.
///
/// Field diverifikasi terhadap `PpdbPendaftaranResource`:
/// `nilai_rata_rata` selalu dihitung backend; `nilai_rapor`, `sekolah`,
/// `gelombang`, dan `dokumens` hanya hadir bila relasinya di-load
/// (index memuat sekolah+gelombang; show juga memuat dokumens).
class PpdbPendaftarModel {
  final int id;
  final int? sekolahId;
  final int? gelombangId;
  final String noPendaftaran;
  final String namaLengkap;
  final String? email;
  final String? nisn;
  final int? jenisKelamin;
  final String? jenisKelaminLabel;
  final String? telpHp;
  final String? asalSekolah;
  final String statusPendaftaran;
  final String? tanggalLahir;
  final int? usia;
  final int? jumlahPrestasi;
  final String? tingkatPrestasiTertinggi;
  final int? poinPelanggaran;
  final bool isHafidz;
  final int? juzHafalan;
  final double? nilaiRataRata;
  final String? namaGelombang;
  final String? namaSekolah;
  final List<PpdbDokumenModel> dokumens;
  final bool isSuspectFraud;
  final String? fraudReason;
  final String? createdAt;

  const PpdbPendaftarModel({
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

  factory PpdbPendaftarModel.fromJson(Map<String, dynamic> json) {
    final gelombangRaw = json['gelombang'];
    final sekolahRaw = json['sekolah'];
    final dokumensRaw = json['dokumens'];

    return PpdbPendaftarModel(
      id: parseIntOrNull(json['id']) ?? 0,
      sekolahId: parseIntOrNull(json['mst_sekolah_id']),
      gelombangId: parseIntOrNull(json['ppdb_gelombang_id']),
      noPendaftaran: json['no_pendaftaran'] as String? ?? '',
      namaLengkap: json['nama_lengkap'] as String? ?? '',
      email: json['email'] as String?,
      nisn: json['nisn'] as String?,
      jenisKelamin: parseIntOrNull(json['jenis_kelamin']),
      jenisKelaminLabel: json['jenis_kelamin_label'] as String?,
      telpHp: json['telp_hp'] as String?,
      asalSekolah: json['asal_sekolah'] as String?,
      statusPendaftaran: json['status_pendaftaran'] as String? ?? 'draft',
      tanggalLahir: json['tanggal_lahir'] as String?,
      usia: parseIntOrNull(json['usia']),
      jumlahPrestasi: parseIntOrNull(json['jumlah_prestasi']),
      tingkatPrestasiTertinggi: json['tingkat_prestasi_tertinggi'] as String?,
      poinPelanggaran: parseIntOrNull(json['poin_pelanggaran']),
      isHafidz: parseBool(json['is_hafidz']),
      juzHafalan: parseIntOrNull(json['juz_hafalan']),
      nilaiRataRata: parseDoubleOrNull(json['nilai_rata_rata']),
      namaGelombang: gelombangRaw is Map<String, dynamic>
          ? gelombangRaw['nama_gelombang'] as String?
          : null,
      namaSekolah: sekolahRaw is Map<String, dynamic>
          ? sekolahRaw['nama_sekolah'] as String?
          : null,
      dokumens: dokumensRaw is List
          ? dokumensRaw
                .whereType<Map<String, dynamic>>()
                .map(PpdbDokumenModel.fromJson)
                .toList()
          : const [],
      isSuspectFraud: parseBool(json['is_suspect_fraud']),
      fraudReason: json['fraud_reason'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  PpdbPendaftarEntity toEntity() => PpdbPendaftarEntity(
    id: id,
    sekolahId: sekolahId,
    gelombangId: gelombangId,
    noPendaftaran: noPendaftaran,
    namaLengkap: namaLengkap,
    email: email,
    nisn: nisn,
    jenisKelamin: jenisKelamin,
    jenisKelaminLabel: jenisKelaminLabel,
    telpHp: telpHp,
    asalSekolah: asalSekolah,
    statusPendaftaran: statusPendaftaran,
    tanggalLahir: tanggalLahir,
    usia: usia,
    jumlahPrestasi: jumlahPrestasi,
    tingkatPrestasiTertinggi: tingkatPrestasiTertinggi,
    poinPelanggaran: poinPelanggaran,
    isHafidz: isHafidz,
    juzHafalan: juzHafalan,
    nilaiRataRata: nilaiRataRata,
    namaGelombang: namaGelombang,
    namaSekolah: namaSekolah,
    dokumens: dokumens.map((d) => d.toEntity()).toList(),
    isSuspectFraud: isSuspectFraud,
    fraudReason: fraudReason,
    createdAt: createdAt,
  );
}
