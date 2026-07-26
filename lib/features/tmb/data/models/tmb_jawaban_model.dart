import '../../domain/entities/tmb_jawaban_entity.dart';

/// Model `trx_tes_minat_bakat_jawaban`.
class TmbJawabanModel {
  final int id;
  final int pesertaId;
  final int pertanyaanId;
  final int? opsiId;
  final String? jawabanTeks;
  final int nilai;

  const TmbJawabanModel({
    required this.id,
    required this.pesertaId,
    required this.pertanyaanId,
    this.opsiId,
    this.jawabanTeks,
    this.nilai = 0,
  });

  factory TmbJawabanModel.fromJson(Map<String, dynamic> json) =>
      TmbJawabanModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        pesertaId: (json['peserta_id'] as num?)?.toInt() ?? 0,
        pertanyaanId: (json['pertanyaan_id'] as num?)?.toInt() ?? 0,
        opsiId: (json['opsi_id'] as num?)?.toInt(),
        jawabanTeks: json['jawaban_teks'] as String?,
        nilai: (json['nilai'] as num?)?.toInt() ?? 0,
      );

  TmbJawabanEntity toEntity() => TmbJawabanEntity(
    id: id,
    pesertaId: pesertaId,
    pertanyaanId: pertanyaanId,
    opsiId: opsiId,
    jawabanTeks: jawabanTeks,
    nilai: nilai,
  );
}
