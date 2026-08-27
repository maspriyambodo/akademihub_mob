import 'package:equatable/equatable.dart';

class AbsensiSiswaEntity extends Equatable {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;

  /// Format: "YYYY-MM-DD"
  final String tanggal;

  /// Label dari backend: "Hadir", "Izin", "Sakit", "Alpha"
  final String statusAbsensi;

  final String? keterangan;
  final String? jamMasuk;
  final String? jamPulang;

  const AbsensiSiswaEntity({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    required this.tanggal,
    required this.statusAbsensi,
    this.keterangan,
    this.jamMasuk,
    this.jamPulang,
  });

  DateTime? get tanggalDate => DateTime.tryParse(tanggal);

  @override
  List<Object?> get props => [id];
}
