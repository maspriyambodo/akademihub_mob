import 'package:equatable/equatable.dart';

/// Jawaban satu pertanyaan (`trx_tes_minat_bakat_jawaban`).
///
/// Backend melakukan upsert per pasangan (`peserta_id`, `pertanyaan_id`),
/// jadi mengirim ulang `POST /tes-minat-bakat-jawaban` untuk pertanyaan yang
/// sama akan menimpa jawaban sebelumnya.
class TmbJawabanEntity extends Equatable {
  final int id;
  final int pesertaId;
  final int pertanyaanId;
  final int? opsiId;
  final String? jawabanTeks;
  final int nilai;

  const TmbJawabanEntity({
    required this.id,
    required this.pesertaId,
    required this.pertanyaanId,
    this.opsiId,
    this.jawabanTeks,
    this.nilai = 0,
  });

  @override
  List<Object?> get props => [id, pertanyaanId, opsiId, jawabanTeks, nilai];
}
