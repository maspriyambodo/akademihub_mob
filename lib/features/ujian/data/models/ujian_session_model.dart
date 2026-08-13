import '../../domain/entities/ujian_session_entity.dart';

class UjianSessionModel {
  final int id;
  final int ujianId;
  final String namaUjian;
  final int status;
  final String? waktuMulai;
  final String? waktuSelesai;
  final int totalBenar;
  final int totalSalah;
  final double nilaiAkhir;
  final int? sisaWaktu;

  const UjianSessionModel({
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

  factory UjianSessionModel.fromJson(Map<String, dynamic> json) {
    final ujian = json['ujian'] is Map ? json['ujian'] as Map : null;
    return UjianSessionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ujianId:
          (json['trx_ujian_id'] as num?)?.toInt() ??
          (ujian?['id'] as num?)?.toInt() ??
          0,
      namaUjian: ujian?['nama']?.toString() ?? 'Ujian',
      status: (json['status'] as num?)?.toInt() ?? 0,
      waktuMulai: json['waktu_mulai']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      totalBenar: (json['total_benar'] as num?)?.toInt() ?? 0,
      totalSalah: (json['total_salah'] as num?)?.toInt() ?? 0,
      nilaiAkhir: (json['nilai_akhir'] as num?)?.toDouble() ?? 0,
      sisaWaktu: (json['sisa_waktu'] as num?)?.toInt(),
    );
  }

  UjianSessionEntity toEntity() => UjianSessionEntity(
    id: id,
    ujianId: ujianId,
    namaUjian: namaUjian,
    // exam-engine memakai 0/1/2 pada response API.
    status: switch (status) {
      1 => UjianSessionStatus.mengerjakan,
      2 => UjianSessionStatus.selesai,
      _ => UjianSessionStatus.belumMulai,
    },
    waktuMulai: waktuMulai,
    waktuSelesai: waktuSelesai,
    totalBenar: totalBenar,
    totalSalah: totalSalah,
    nilaiAkhir: nilaiAkhir,
    sisaWaktu: sisaWaktu,
  );
}
