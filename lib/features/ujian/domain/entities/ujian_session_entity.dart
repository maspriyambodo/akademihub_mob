import 'package:equatable/equatable.dart';

enum UjianSessionStatus { belumMulai, mengerjakan, selesai }

class UjianSessionEntity extends Equatable {
  final int id;
  final int ujianId;
  final String namaUjian;
  final UjianSessionStatus status;
  final String? waktuMulai;
  final String? waktuSelesai;
  final int totalBenar;
  final int totalSalah;
  final double nilaiAkhir;
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
    this.nilaiAkhir = 0,
    this.sisaWaktu,
  });

  String get statusLabel => switch (status) {
    UjianSessionStatus.belumMulai => 'Belum mulai',
    UjianSessionStatus.mengerjakan => 'Mengerjakan',
    UjianSessionStatus.selesai => 'Selesai',
  };

  UjianSessionEntity copyWith({
    UjianSessionStatus? status,
    String? waktuMulai,
    String? waktuSelesai,
    int? totalBenar,
    int? totalSalah,
    double? nilaiAkhir,
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
    sisaWaktu,
  ];
}
