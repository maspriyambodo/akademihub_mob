import '../../domain/entities/bk_siswa_ringkas_entity.dart';

/// Model ringkasan siswa — field dari `SiswaResource`:
/// `id`, `nis`, `nama`, `kelas{ id, nama_kelas }` (bila relasi dimuat).
class BkSiswaRingkasModel {
  final int id;
  final String? nis;
  final String nama;
  final String? namaKelas;

  const BkSiswaRingkasModel({
    required this.id,
    this.nis,
    required this.nama,
    this.namaKelas,
  });

  factory BkSiswaRingkasModel.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'] is Map<String, dynamic>
        ? json['kelas'] as Map<String, dynamic>
        : null;
    return BkSiswaRingkasModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nis: json['nis']?.toString(),
      nama: json['nama'] as String? ?? '-',
      namaKelas: kelas?['nama_kelas'] as String?,
    );
  }

  BkSiswaRingkasEntity toEntity() =>
      BkSiswaRingkasEntity(id: id, nis: nis, nama: nama, namaKelas: namaKelas);
}
