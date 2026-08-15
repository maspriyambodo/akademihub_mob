import 'package:equatable/equatable.dart';

enum UjianSessionStatus { belumMulai, mengerjakan, selesai, menungguKoreksi }

class UjianSessionEntity extends Equatable {
  final int id;
  final int ujianId;
  final String namaUjian;
  final UjianSessionStatus status;
  final String? waktuMulai;
  final String? waktuSelesai;
  final int totalBenar;
  final int totalSalah;
  final double? nilaiAkhir;
  final double? nilaiProvisional;
  final int? sisaWaktu;

  const UjianSessionEntity({
    required this.id,
    required this.ujianId,
    required this.namaUjian,
    required this.status,
    this.waktuMulai,
    this.waktuSelesai,
    this.totalBenar = 0,
    this.totalSalah = 0,
    this.nilaiAkhir,
    this.nilaiProvisional,
    this.sisaWaktu,
  });

  String get statusLabel => switch (status) {
    UjianSessionStatus.belumMulai => 'Belum mulai',
    UjianSessionStatus.mengerjakan => 'Mengerjakan',
    UjianSessionStatus.selesai => 'Selesai',
    UjianSessionStatus.menungguKoreksi => 'Menunggu koreksi essay',
  };

  UjianSessionEntity copyWith({
    UjianSessionStatus? status,
    String? waktuMulai,
    String? waktuSelesai,
    int? totalBenar,
    int? totalSalah,
    double? nilaiAkhir,
    double? nilaiProvisional,
    int? sisaWaktu,
  }) => UjianSessionEntity(
    id: id,
    ujianId: ujianId,
    namaUjian: namaUjian,
    status: status ?? this.status,
    waktuMulai: waktuMulai ?? this.waktuMulai,
    waktuSelesai: waktuSelesai ?? this.waktuSelesai,
    totalBenar: totalBenar ?? this.totalBenar,
    totalSalah: totalSalah ?? this.totalSalah,
    nilaiAkhir: nilaiAkhir ?? this.nilaiAkhir,
    nilaiProvisional: nilaiProvisional ?? this.nilaiProvisional,
    sisaWaktu: sisaWaktu ?? this.sisaWaktu,
  );

  @override
  List<Object?> get props => [
    id,
    ujianId,
    namaUjian,
    status,
    waktuMulai,
    waktuSelesai,
    totalBenar,
    totalSalah,
    nilaiAkhir,
    nilaiProvisional,
    sisaWaktu,
  ];
}
