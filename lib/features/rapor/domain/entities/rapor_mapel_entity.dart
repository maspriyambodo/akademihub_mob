import 'package:equatable/equatable.dart';

/// Rincian nilai satu mata pelajaran di dalam rapor.
///
/// Backend: `trx_rapor_detail` (lihat `RaporResource.detail[]` dan
/// `RaporService::getRaporDetail()['detail'][]`).
class RaporMapelEntity extends Equatable {
  /// `id` hanya tersedia pada `RaporResource` (endpoint index / by-siswa / show).
  /// Endpoint `/rapor/{id}/detail` TIDAK mengirim `id` per baris mapel.
  final int? id;

  final int? mapelId;
  final String? mapelKode;
  final String? mapelNama;

  final double? nilaiPengetahuan;
  final double? nilaiKeterampilan;
  final double? nilaiAkhir;

  /// A / B / C / D
  final String? predikat;

  final String? deskripsi;

  const RaporMapelEntity({
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

  /// Nilai yang dipakai sebagai angka utama di UI.
  double? get nilaiUtama => nilaiAkhir ?? nilaiPengetahuan ?? nilaiKeterampilan;

  bool get punyaNilaiPengetahuan => nilaiPengetahuan != null;
  bool get punyaNilaiKeterampilan => nilaiKeterampilan != null;

  @override
  List<Object?> get props => [id, mapelId];
}
