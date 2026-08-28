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
  final String? jadwalJamPulang;
  final String? jadwalJamMasuk;
  final String? shiftKode;
  final String? shiftNama;
  final String? timezone;
  final bool terlambat;
  final int menitTerlambat;

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
    this.jadwalJamPulang,
    this.jadwalJamMasuk,
    this.shiftKode,
    this.shiftNama,
    this.timezone,
    this.terlambat = false,
    this.menitTerlambat = 0,
  });

  DateTime? get tanggalDate => DateTime.tryParse(tanggal);

  @override
  List<Object?> get props => [id, jamMasuk, jamPulang];
}
