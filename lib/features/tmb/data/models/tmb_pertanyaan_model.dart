import '../../domain/entities/tmb_pertanyaan_entity.dart';

/// Model `mst_tes_minat_bakat_opsi`.
class TmbOpsiModel {
  final int id;
  final int? pertanyaanId;
  final String teks;
  final int nilai;
  final int? nomorUrut;

  const TmbOpsiModel({
    required this.id,
    this.pertanyaanId,
    required this.teks,
    this.nilai = 0,
    this.nomorUrut,
  });

  factory TmbOpsiModel.fromJson(Map<String, dynamic> json) => TmbOpsiModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    pertanyaanId: (json['pertanyaan_id'] as num?)?.toInt(),
    teks: json['opsi'] as String? ?? '-',
    nilai: (json['nilai'] as num?)?.toInt() ?? 0,
    nomorUrut: (json['nomor_urut'] as num?)?.toInt(),
  );

  TmbOpsiEntity toEntity() => TmbOpsiEntity(
    id: id,
    pertanyaanId: pertanyaanId,
    teks: teks,
    nilai: nilai,
    nomorUrut: nomorUrut,
  );
}

/// Model `mst_tes_minat_bakat_pertanyaan` + relasi `aspek` dan `opsi`.
class TmbPertanyaanModel {
  final int id;
  final int? tesId;
  final int? aspekId;
  final String pertanyaan;
  final int tipePertanyaan;
  final int nomorUrut;
  final int bobot;
  final String? aspekNama;
  final List<TmbOpsiModel> opsi;

  const TmbPertanyaanModel({
    required this.id,
    this.tesId,
    this.aspekId,
    required this.pertanyaan,
    this.tipePertanyaan = 1,
    this.nomorUrut = 0,
    this.bobot = 1,
    this.aspekNama,
    this.opsi = const [],
  });

  factory TmbPertanyaanModel.fromJson(Map<String, dynamic> json) {
    final aspek = json['aspek'];
    final rawOpsi = json['opsi'];
    final opsiList = <TmbOpsiModel>[];
    if (rawOpsi is List) {
      for (final item in rawOpsi) {
        if (item is Map<String, dynamic>) {
          opsiList.add(TmbOpsiModel.fromJson(item));
        }
      }
      // Urutan opsi tidak dijamin backend — urutkan berdasar nomor_urut.
      opsiList.sort(
        (a, b) => (a.nomorUrut ?? a.id).compareTo(b.nomorUrut ?? b.id),
      );
    }

    return TmbPertanyaanModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tesId: (json['tes_id'] as num?)?.toInt(),
      aspekId: (json['aspek_id'] as num?)?.toInt(),
      pertanyaan: json['pertanyaan'] as String? ?? '-',
      tipePertanyaan: (json['tipe_pertanyaan'] as num?)?.toInt() ?? 1,
      nomorUrut: (json['nomor_urut'] as num?)?.toInt() ?? 0,
      bobot: (json['bobot'] as num?)?.toInt() ?? 1,
      aspekNama: aspek is Map ? aspek['nama_aspek'] as String? : null,
      opsi: opsiList,
    );
  }

  TmbPertanyaanEntity toEntity() => TmbPertanyaanEntity(
    id: id,
    tesId: tesId,
    aspekId: aspekId,
    pertanyaan: pertanyaan,
    tipePertanyaan: tipePertanyaan,
    nomorUrut: nomorUrut,
    bobot: bobot,
    aspekNama: aspekNama,
    opsi: opsi.map((o) => o.toEntity()).toList(),
  );
}
