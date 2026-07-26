import 'package:equatable/equatable.dart';

/// Master jenis kasus BK (`mst_bk_jenis`).
class BkJenisEntity extends Equatable {
  final int id;
  final String? kode;
  final String nama;
  final String? keterangan;

  const BkJenisEntity({
    required this.id,
    this.kode,
    required this.nama,
    this.keterangan,
  });

  @override
  List<Object?> get props => [id];
}
