import '../../domain/entities/ujian_nilai_entity.dart';
import 'ujian_model.dart';

/// Angka nilai dari backend bisa berupa num ATAU String desimal.
double? parseUjianNilai(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

/// Satu baris `nilai[]` dari `GET /akademik/ujian/{id}/nilai`
/// (dibentuk manual di `UjianService::getNilaiByUjian`).
class UjianNilaiModel {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final double? nilai;
  final String? keterangan;

  const UjianNilaiModel({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.nilai,
    this.keterangan,
  });

  factory UjianNilaiModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] is Map ? json['siswa'] as Map : null;
    return UjianNilaiModel(
      id: (json['id'] as num).toInt(),
      siswaId: (siswa?['id'] as num?)?.toInt() ??
          (json['mst_siswa_id'] as num?)?.toInt(),
      siswaNama: siswa?['nama'] as String?,
      siswaNis: siswa?['nis']?.toString(),
      nilai: parseUjianNilai(json['nilai']),
      keterangan: json['keterangan'] as String?,
    );
  }

  UjianNilaiEntity toEntity() => UjianNilaiEntity(
    id: id,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    nilai: nilai,
    keterangan: keterangan,
  );
}

/// Payload lengkap `{ ujian: {...}, nilai: [...] }`.
class UjianNilaiDetailModel {
  final UjianModel? ujian;
  final List<UjianNilaiModel> nilai;

  const UjianNilaiDetailModel({this.ujian, this.nilai = const []});

  factory UjianNilaiDetailModel.fromJson(Map<String, dynamic> json) {
    final ujianRaw = json['ujian'];
    final nilaiRaw = json['nilai'];
    return UjianNilaiDetailModel(
      ujian: ujianRaw is Map<String, dynamic>
          ? UjianModel.fromJson(ujianRaw)
          : null,
      nilai: nilaiRaw is List
          ? nilaiRaw
                .whereType<Map<String, dynamic>>()
                .map(UjianNilaiModel.fromJson)
                .toList()
          : const [],
    );
  }

  UjianNilaiDetailEntity toEntity() => UjianNilaiDetailEntity(
    ujian: ujian?.toEntity(),
    nilai: nilai.map((n) => n.toEntity()).toList(),
  );
}
