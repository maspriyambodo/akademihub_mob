import 'package:equatable/equatable.dart';

class AbsensiGuruEntity extends Equatable {
  final int id;
  final int? guruId;
  final String? guruNama;
  final String? guruNip;

  /// Format: "YYYY-MM-DD"
  final String tanggal;

  /// Label dari backend: "Hadir", "Izin", "Sakit", "Alpha"
  final String statusAbsensi;

  final String? keterangan;
  final String? jamMasuk;
  final String? jamKeluar;

  const AbsensiGuruEntity({
    required this.id,
    this.guruId,
    this.guruNama,
    this.guruNip,
    required this.tanggal,
    required this.statusAbsensi,
    this.keterangan,
    this.jamMasuk,
    this.jamKeluar,
  });

  DateTime? get tanggalDate => DateTime.tryParse(tanggal);

  @override
  List<Object?> get props => [id];
}
