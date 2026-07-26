import 'package:equatable/equatable.dart';

/// Opsi jawaban satu pertanyaan (`mst_tes_minat_bakat_opsi`).
class TmbOpsiEntity extends Equatable {
  final int id;
  final int? pertanyaanId;
  final String teks;
  final int nilai;
  final int? nomorUrut;

  const TmbOpsiEntity({
    required this.id,
    this.pertanyaanId,
    required this.teks,
    this.nilai = 0,
    this.nomorUrut,
  });

  @override
  List<Object?> get props => [id, teks, nilai];
}

/// Pertanyaan tes minat bakat (`mst_tes_minat_bakat_pertanyaan`).
class TmbPertanyaanEntity extends Equatable {
  final int id;
  final int? tesId;
  final int? aspekId;
  final String pertanyaan;

  /// 1=single choice, 2=multiple choice, 3=likert scale. Backend hanya
  /// menyimpan SATU jawaban per pertanyaan (upsert per `pertanyaan_id`),
  /// sehingga semua tipe dirender sebagai pilihan tunggal.
  final int tipePertanyaan;

  final int nomorUrut;
  final int bobot;
  final String? aspekNama;
  final List<TmbOpsiEntity> opsi;

  const TmbPertanyaanEntity({
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

  /// Pertanyaan tanpa opsi dijawab dengan teks bebas (`jawaban_teks`).
  bool get adaOpsi => opsi.isNotEmpty;

  @override
  List<Object?> get props => [id, pertanyaan, opsi];
}
