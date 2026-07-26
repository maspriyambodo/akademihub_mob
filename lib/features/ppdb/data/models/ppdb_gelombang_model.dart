import '../../domain/entities/ppdb_gelombang_entity.dart';
import 'ppdb_parse_utils.dart';

/// Model gelombang PPDB.
///
/// Field diverifikasi terhadap `PpdbGelombangResource` +
/// model `App\Models\Ppdb\PpdbGelombang` di backend.
class PpdbGelombangModel {
  final int id;
  final int? sekolahId;
  final String namaGelombang;
  final String tglMulai;
  final String tglSelesai;
  final double? biayaPendaftaran;
  final bool isActive;
  final bool? isActivePeriod;
  final int? kuotaTotal;
  final bool isSeleksiOtomatis;
  final int? metodeSeleksi;
  final String? metodeSeleksiLabel;
  final String? tahunAjaran;

  const PpdbGelombangModel({
    required this.id,
    this.sekolahId,
    required this.namaGelombang,
    this.tglMulai = '',
    this.tglSelesai = '',
    this.biayaPendaftaran,
    this.isActive = false,
    this.isActivePeriod,
    this.kuotaTotal,
    this.isSeleksiOtomatis = false,
    this.metodeSeleksi,
    this.metodeSeleksiLabel,
    this.tahunAjaran,
  });

  factory PpdbGelombangModel.fromJson(Map<String, dynamic> json) {
    final tahunAjaranRaw = json['tahunAjaran'];
    return PpdbGelombangModel(
      id: parseIntOrNull(json['id']) ?? 0,
      sekolahId: parseIntOrNull(json['mst_sekolah_id']),
      namaGelombang: json['nama_gelombang'] as String? ?? '',
      tglMulai: parseTanggal(json['tgl_mulai']),
      tglSelesai: parseTanggal(json['tgl_selesai']),
      biayaPendaftaran: parseDoubleOrNull(json['biaya_pendaftaran']),
      isActive: parseBool(json['is_active']),
      isActivePeriod: json['is_active_period'] == null
          ? null
          : parseBool(json['is_active_period']),
      kuotaTotal: parseIntOrNull(json['kuota_total']),
      isSeleksiOtomatis: parseBool(json['is_seleksi_otomatis']),
      metodeSeleksi: parseIntOrNull(json['metode_seleksi']),
      metodeSeleksiLabel: json['metode_seleksi_label'] as String?,
      tahunAjaran: tahunAjaranRaw is Map<String, dynamic>
          ? tahunAjaranRaw['tahun_ajaran'] as String?
          : null,
    );
  }

  PpdbGelombangEntity toEntity() => PpdbGelombangEntity(
    id: id,
    sekolahId: sekolahId,
    namaGelombang: namaGelombang,
    tglMulai: tglMulai,
    tglSelesai: tglSelesai,
    biayaPendaftaran: biayaPendaftaran,
    isActive: isActive,
    isActivePeriod: isActivePeriod,
    kuotaTotal: kuotaTotal,
    isSeleksiOtomatis: isSeleksiOtomatis,
    metodeSeleksi: metodeSeleksi,
    metodeSeleksiLabel: metodeSeleksiLabel,
    tahunAjaran: tahunAjaran,
  );
}
