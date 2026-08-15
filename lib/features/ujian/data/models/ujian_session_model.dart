import '../../domain/entities/ujian_session_entity.dart';
import '../../../../core/error/exceptions.dart';

class UjianSessionModel {
  final int id;
  final int ujianId;
  final String namaUjian;
  final int status;
  final String? statusCode;
  final String? waktuMulai;
  final String? deadlineAt;
  final String? waktuSelesai;
  final String? timedOutAt;
  final int totalBenar;
  final int totalSalah;
  final double? nilaiAkhir;
  final double? nilaiProvisional;
  final int? sisaWaktu;

  const UjianSessionModel({
    required this.id,
    required this.ujianId,
    required this.namaUjian,
    required this.status,
    this.statusCode,
    this.waktuMulai,
    this.deadlineAt,
    this.waktuSelesai,
    this.timedOutAt,
    this.totalBenar = 0,
    this.totalSalah = 0,
    this.nilaiAkhir,
    this.nilaiProvisional,
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
      statusCode: json['status_code']?.toString(),
      waktuMulai: json['waktu_mulai']?.toString(),
      deadlineAt: json['deadline_at']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      timedOutAt: json['timed_out_at']?.toString(),
      totalBenar: (json['total_benar'] as num?)?.toInt() ?? 0,
      totalSalah: (json['total_salah'] as num?)?.toInt() ?? 0,
      nilaiAkhir: (json['nilai_akhir'] as num?)?.toDouble(),
      nilaiProvisional: (json['nilai_provisional'] as num?)?.toDouble(),
      sisaWaktu: (json['sisa_waktu'] as num?)?.toInt(),
    );
  }

  UjianSessionStatus _parseStatus() {
    final code = statusCode?.trim();
    if (code != null && code.isNotEmpty) {
      return switch (code) {
        'not_started' => UjianSessionStatus.belumMulai,
        'in_progress' => UjianSessionStatus.mengerjakan,
        'completed' => UjianSessionStatus.selesai,
        'awaiting_grading' => UjianSessionStatus.menungguKoreksi,
        _ => throw ServerException(
          'Kontrak status sesi ujian tidak dikenal: $code',
        ),
      };
    }

    return switch (status) {
      1 => UjianSessionStatus.belumMulai,
      2 => UjianSessionStatus.mengerjakan,
      3 => UjianSessionStatus.selesai,
      4 => UjianSessionStatus.menungguKoreksi,
      _ => throw ServerException(
        'Kontrak status sesi ujian tidak dikenal: $status',
      ),
    };
  }

  UjianSessionEntity toEntity() => UjianSessionEntity(
    id: id,
    ujianId: ujianId,
    namaUjian: namaUjian,
    status: _parseStatus(),
    waktuMulai: waktuMulai,
    deadlineAt: deadlineAt,
    waktuSelesai: waktuSelesai,
    timedOutAt: timedOutAt,
    totalBenar: totalBenar,
    totalSalah: totalSalah,
    nilaiAkhir: nilaiAkhir,
    nilaiProvisional: nilaiProvisional,
    sisaWaktu: sisaWaktu,
  );
}
