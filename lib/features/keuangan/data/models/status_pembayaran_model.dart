import '../../domain/entities/status_pembayaran_entity.dart';
import 'keuangan_json.dart';

/// Mapping dari `PembayaranSppService::getStatusPembayaranSiswa()`.
/// Endpoint: `GET /keuangan/pembayaran-spp/siswa/{siswaId}/status`
///
/// `data` berupa OBJEK (bukan list):
/// ```json
/// {
///   "tahun_ajaran": "2026/2027",
///   "total_bulan": 12,
///   "lunas": 5,
///   "belum_lunas": 2,
///   "bulan_lunas": [1,2,3,4,5],
///   "bulan_belum_lunas": {"5":6,"6":7,"7":8}
/// }
/// ```
class StatusPembayaranModel {
  final String? tahunAjaran;
  final int totalBulan;
  final int lunas;
  final int belumLunas;
  final List<int> bulanLunas;
  final List<int> bulanBelumLunas;

  const StatusPembayaranModel({
    this.tahunAjaran,
    this.totalBulan = 12,
    this.lunas = 0,
    this.belumLunas = 0,
    this.bulanLunas = const [],
    this.bulanBelumLunas = const [],
  });

  factory StatusPembayaranModel.fromJson(Map<String, dynamic> json) {
    return StatusPembayaranModel(
      tahunAjaran: keuToText(json['tahun_ajaran']),
      totalBulan: keuToIntOr(json['total_bulan'], 12),
      lunas: keuToIntOr(json['lunas']),
      belumLunas: keuToIntOr(json['belum_lunas']),
      bulanLunas: keuToIntList(json['bulan_lunas']),
      bulanBelumLunas: keuToIntList(json['bulan_belum_lunas']),
    );
  }

  StatusPembayaranEntity toEntity() => StatusPembayaranEntity(
    tahunAjaran: tahunAjaran,
    totalBulan: totalBulan,
    lunas: lunas,
    belumLunas: belumLunas,
    bulanLunas: bulanLunas,
    bulanBelumLunas: bulanBelumLunas,
  );
}
