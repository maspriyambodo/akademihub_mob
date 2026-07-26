import '../../domain/entities/rapor_mapel_entity.dart';

/// Kolom nilai di backend memakai cast Eloquent `decimal:2`, yang di-serialize
/// menjadi STRING ("85.50") — bukan number. Parser harus menerima keduanya.
double? raporToDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? raporToInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? raporToText(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

/// Ubah `detail` mentah (List) menjadi list model mapel.
List<RaporMapelModel> raporMapelListFromJson(dynamic raw) {
  if (raw is! List) return const [];
  final result = <RaporMapelModel>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      result.add(RaporMapelModel.fromJson(item));
    }
  }
  return result;
}

class RaporMapelModel {
  final int? id;
  final int? mapelId;
  final String? mapelKode;
  final String? mapelNama;
  final double? nilaiPengetahuan;
  final double? nilaiKeterampilan;
  final double? nilaiAkhir;
  final String? predikat;
  final String? deskripsi;

  const RaporMapelModel({
    this.id,
    this.mapelId,
    this.mapelKode,
    this.mapelNama,
    this.nilaiPengetahuan,
    this.nilaiKeterampilan,
    this.nilaiAkhir,
    this.predikat,
    this.deskripsi,
  });

  factory RaporMapelModel.fromJson(Map<String, dynamic> json) {
    final mapel = json['mapel'] as Map<String, dynamic>?;
    return RaporMapelModel(
      id: raporToInt(json['id']),
      mapelId: raporToInt(mapel?['id']),
      mapelKode: raporToText(mapel?['kode']),
      mapelNama: raporToText(mapel?['nama']),
      nilaiPengetahuan: raporToDouble(json['nilai_pengetahuan']),
      nilaiKeterampilan: raporToDouble(json['nilai_keterampilan']),
      nilaiAkhir: raporToDouble(json['nilai_akhir']),
      predikat: raporToText(json['predikat']),
      deskripsi: raporToText(json['deskripsi']),
    );
  }

  RaporMapelEntity toEntity() => RaporMapelEntity(
    id: id,
    mapelId: mapelId,
    mapelKode: mapelKode,
    mapelNama: mapelNama,
    nilaiPengetahuan: nilaiPengetahuan,
    nilaiKeterampilan: nilaiKeterampilan,
    nilaiAkhir: nilaiAkhir,
    predikat: predikat,
    deskripsi: deskripsi,
  );
}
