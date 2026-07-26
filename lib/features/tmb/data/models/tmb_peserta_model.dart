import '../../domain/entities/tmb_peserta_entity.dart';
import 'tmb_hasil_model.dart';
import 'tmb_tes_model.dart';

/// Model `trx_tes_minat_bakat_peserta` + relasi `tes`, `siswa.kelas`,
/// dan `hasil.aspek` (dimuat oleh endpoint by-siswa/by-tes/selesaikan).
class TmbPesertaModel {
  final int id;
  final int tesId;
  final int siswaId;
  final int status;
  final String? waktuMulai;
  final String? waktuSelesai;
  final int? progressPersen;
  final String? siswaNama;
  final String? siswaNis;
  final String? kelasNama;
  final TmbTesModel? tes;
  final List<TmbHasilModel> hasil;

  const TmbPesertaModel({
    required this.id,
    required this.tesId,
    required this.siswaId,
    this.status = 0,
    this.waktuMulai,
    this.waktuSelesai,
    this.progressPersen,
    this.siswaNama,
    this.siswaNis,
    this.kelasNama,
    this.tes,
    this.hasil = const [],
  });

  factory TmbPesertaModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'];
    final kelas = siswa is Map ? siswa['kelas'] : null;
    final rawTes = json['tes'];
    final rawHasil = json['hasil'];

    final hasilList = <TmbHasilModel>[];
    if (rawHasil is List) {
      for (final item in rawHasil) {
        if (item is Map<String, dynamic>) {
          hasilList.add(TmbHasilModel.fromJson(item));
        }
      }
    }

    return TmbPesertaModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tesId: (json['tes_id'] as num?)?.toInt() ?? 0,
      siswaId: (json['siswa_id'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      waktuMulai: json['waktu_mulai'] as String?,
      waktuSelesai: json['waktu_selesai'] as String?,
      progressPersen: (json['progress_persen'] as num?)?.toInt(),
      siswaNama: siswa is Map ? siswa['nama'] as String? : null,
      siswaNis: siswa is Map ? siswa['nis'] as String? : null,
      kelasNama: kelas is Map ? kelas['nama_kelas'] as String? : null,
      tes: rawTes is Map<String, dynamic> ? TmbTesModel.fromJson(rawTes) : null,
      hasil: hasilList,
    );
  }

  TmbPesertaEntity toEntity() => TmbPesertaEntity(
    id: id,
    tesId: tesId,
    siswaId: siswaId,
    status: status,
    waktuMulai: waktuMulai,
    waktuSelesai: waktuSelesai,
    progressPersen: progressPersen,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    kelasNama: kelasNama,
    tes: tes?.toEntity(),
    hasil: hasil.map((h) => h.toEntity()).toList(),
  );
}
