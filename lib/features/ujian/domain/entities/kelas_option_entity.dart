import 'package:equatable/equatable.dart';

/// Pilihan kelas untuk pemilih kelas (guru/admin), dari `KelasResource`
/// (`GET /kelas`): `id`, `nama_kelas`, `tingkat`, `tahun_ajaran_id`,
/// `tahun_ajaran` (nama).
class KelasOptionEntity extends Equatable {
  final int id;
  final String namaKelas;
  final int? tingkat;

  /// Dipakai sebagai prefill `tahun_ajaran` saat generate/export ranking.
  final int? tahunAjaranId;
  final String? tahunAjaranNama;

  const KelasOptionEntity({
    required this.id,
    required this.namaKelas,
    this.tingkat,
    this.tahunAjaranId,
    this.tahunAjaranNama,
  });

  @override
  List<Object?> get props => [id];
}
