import 'package:equatable/equatable.dart';

/// Tarif SPP per kelas per tahun ajaran.
///
/// Backend: `MstTarifSpp` + `TarifSppResource`.
/// Endpoint:
/// - `GET /keuangan/tarif-spp`                  (index, terpaginasi)
/// - `GET /keuangan/tarif-spp/{id}`             (show)
/// - `GET /keuangan/tarif-spp/kelas/{kelasId}`  (satu objek, bukan list;
///   404 bila kelas tersebut belum punya tarif)
class TarifSppEntity extends Equatable {
  final int id;

  /// `kelas.id` — relasi `whenLoaded`, bisa hilang dari JSON.
  final int? kelasId;

  /// `kelas.nama_kelas`
  final String? kelasNama;

  /// `kelas.tingkat`
  final String? tingkat;

  /// `tahun_ajaran` — backend mengirim NAMA tahun ajaran (string), bukan objek.
  final String? tahunAjaran;

  /// `nominal` — string desimal ("350000.00") di JSON.
  final double? nominal;

  final String? keterangan;

  const TarifSppEntity({
    required this.id,
    this.kelasId,
    this.kelasNama,
    this.tingkat,
    this.tahunAjaran,
    this.nominal,
    this.keterangan,
  });

  @override
  List<Object?> get props => [id];
}
