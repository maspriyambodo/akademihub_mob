import 'package:equatable/equatable.dart';

/// Ringkasan siswa dari endpoint master `GET /siswa` (permission `siswa.view`)
/// — dipakai untuk pemilih siswa pada form kasus baru.
class BkSiswaRingkasEntity extends Equatable {
  final int id;
  final String? nis;
  final String nama;
  final String? namaKelas;

  const BkSiswaRingkasEntity({
    required this.id,
    this.nis,
    required this.nama,
    this.namaKelas,
  });

  @override
  List<Object?> get props => [id];
}
