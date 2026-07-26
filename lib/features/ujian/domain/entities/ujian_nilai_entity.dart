import 'package:equatable/equatable.dart';

import 'ujian_entity.dart';

/// Satu baris nilai siswa pada sebuah ujian
/// (elemen `nilai[]` dari `GET /akademik/ujian/{id}/nilai`).
class UjianNilaiEntity extends Equatable {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final double? nilai;
  final String? keterangan;

  const UjianNilaiEntity({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.nilai,
    this.keterangan,
  });

  @override
  List<Object?> get props => [id];
}

/// Payload lengkap `GET /akademik/ujian/{id}/nilai`:
/// info ujian + daftar nilai seluruh siswa pada ujian tersebut.
class UjianNilaiDetailEntity extends Equatable {
  final UjianEntity? ujian;
  final List<UjianNilaiEntity> nilai;

  const UjianNilaiDetailEntity({this.ujian, this.nilai = const []});

  @override
  List<Object?> get props => [ujian, nilai];
}
