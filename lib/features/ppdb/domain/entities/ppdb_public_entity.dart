import 'package:equatable/equatable.dart';

class PpdbSekolahEntity extends Equatable {
  final int id;
  final String nama;

  const PpdbSekolahEntity({required this.id, required this.nama});

  @override
  List<Object?> get props => [id, nama];
}

class PpdbStatusPublikEntity extends Equatable {
  final String noPendaftaran;
  final String namaLengkap;
  final String status;
  final String? namaGelombang;
  final DateTime? tanggalDaftar;

  const PpdbStatusPublikEntity({
    required this.noPendaftaran,
    required this.namaLengkap,
    required this.status,
    this.namaGelombang,
    this.tanggalDaftar,
  });

  @override
  List<Object?> get props => [
    noPendaftaran,
    namaLengkap,
    status,
    namaGelombang,
    tanggalDaftar,
  ];
}

class PpdbPendaftaranPublikEntity extends Equatable {
  final String noPendaftaran;
  final String namaLengkap;
  final String status;

  const PpdbPendaftaranPublikEntity({
    required this.noPendaftaran,
    required this.namaLengkap,
    required this.status,
  });

  @override
  List<Object?> get props => [noPendaftaran, namaLengkap, status];
}
