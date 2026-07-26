import '../../domain/entities/tmb_hasil_entity.dart';

/// Model `trx_tes_minat_bakat_hasil` + relasi `aspek`.
class TmbHasilModel {
  final int id;
  final int? pesertaId;
  final int? aspekId;
  final int skorTotal;
  final int? skorPersen;
  final int? peringkat;
  final String? kategoriHasil;
  final String? interpretasi;
  final String? rekomendasi;
  final String? aspekKode;
  final String? aspekNama;
  final String? aspekDeskripsi;

  const TmbHasilModel({
    required this.id,
    this.pesertaId,
    this.aspekId,
    this.skorTotal = 0,
    this.skorPersen,
    this.peringkat,
    this.kategoriHasil,
    this.interpretasi,
    this.rekomendasi,
    this.aspekKode,
    this.aspekNama,
    this.aspekDeskripsi,
  });

  factory TmbHasilModel.fromJson(Map<String, dynamic> json) {
    final aspek = json['aspek'];
    return TmbHasilModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      pesertaId: (json['peserta_id'] as num?)?.toInt(),
      aspekId: (json['aspek_id'] as num?)?.toInt(),
      skorTotal: (json['skor_total'] as num?)?.toInt() ?? 0,
      skorPersen: (json['skor_persen'] as num?)?.toInt(),
      peringkat: (json['peringkat'] as num?)?.toInt(),
      kategoriHasil: json['kategori_hasil'] as String?,
      interpretasi: json['interpretasi'] as String?,
      rekomendasi: json['rekomendasi'] as String?,
      aspekKode: aspek is Map ? aspek['kode_aspek'] as String? : null,
      aspekNama: aspek is Map ? aspek['nama_aspek'] as String? : null,
      aspekDeskripsi: aspek is Map ? aspek['deskripsi'] as String? : null,
    );
  }

  TmbHasilEntity toEntity() => TmbHasilEntity(
    id: id,
    pesertaId: pesertaId,
    aspekId: aspekId,
    skorTotal: skorTotal,
    skorPersen: skorPersen,
    peringkat: peringkat,
    kategoriHasil: kategoriHasil,
    interpretasi: interpretasi,
    rekomendasi: rekomendasi,
    aspekKode: aspekKode,
    aspekNama: aspekNama,
    aspekDeskripsi: aspekDeskripsi,
  );
}
