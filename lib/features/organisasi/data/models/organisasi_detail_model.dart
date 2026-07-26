import '../../domain/entities/organisasi_detail_entity.dart';
import 'organisasi_anggota_model.dart';
import 'organisasi_model.dart';

/// Model detail organisasi dari `GET /organisasi/{id}`:
/// model `MstOrganisasi` mentah + relasi `pembina`, `anggota.jabatan`,
/// `anggota.siswa`.
class OrganisasiDetailModel {
  final OrganisasiModel organisasi;
  final List<OrganisasiAnggotaModel> anggota;

  const OrganisasiDetailModel({
    required this.organisasi,
    this.anggota = const [],
  });

  factory OrganisasiDetailModel.fromJson(Map<String, dynamic> json) {
    final anggotaRaw = json['anggota'];
    final anggota = <OrganisasiAnggotaModel>[];
    if (anggotaRaw is List) {
      for (final item in anggotaRaw) {
        if (item is Map<String, dynamic>) {
          anggota.add(OrganisasiAnggotaModel.fromJson(item));
        }
      }
    }

    return OrganisasiDetailModel(
      organisasi: OrganisasiModel.fromJson(json),
      anggota: anggota,
    );
  }

  OrganisasiDetailEntity toEntity() => OrganisasiDetailEntity(
    organisasi: organisasi.toEntity(),
    anggota: anggota.map((a) => a.toEntity()).toList(),
  );
}
