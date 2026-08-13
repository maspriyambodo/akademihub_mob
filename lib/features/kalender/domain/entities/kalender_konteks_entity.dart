import 'package:equatable/equatable.dart';

/// Tahun ajaran (`mst_tahun_ajaran`).
class TahunAjaranEntity extends Equatable {
  final int id;
  final String kode;
  final String nama;

  /// "YYYY-MM-DD"
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final bool isActive;

  const TahunAjaranEntity({
    required this.id,
    required this.kode,
    required this.nama,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [id];
}

/// Semester (`mst_semester`).
class SemesterEntity extends Equatable {
  final int id;
  final int? tahunAjaranId;
  final String nama;
  final String? tahunAjaranNama;

  /// "YYYY-MM-DD"
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final bool isActive;

  const SemesterEntity({
    required this.id,
    this.tahunAjaranId,
    required this.nama,
    this.tahunAjaranNama,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [id];
}

/// Hari operasional sekolah (`mst_hari_operasional`).
///
/// Kolom `hari` dibatasi CHECK constraint ke: MON, TUE, WED, THU, FRI, SAT, SUN.
class HariOperasionalEntity extends Equatable {
  final int id;
  final String hari;
  final bool isActive;

  const HariOperasionalEntity({
    required this.id,
    required this.hari,
    this.isActive = true,
  });

  /// Nomor hari ala `DateTime.weekday` (1 = Senin … 7 = Minggu).
  /// Mengembalikan 0 bila kode tidak dikenal.
  int get weekday {
    switch (hari.trim().toUpperCase()) {
      case 'MON':
        return DateTime.monday;
      case 'TUE':
        return DateTime.tuesday;
      case 'WED':
        return DateTime.wednesday;
      case 'THU':
        return DateTime.thursday;
      case 'FRI':
        return DateTime.friday;
      case 'SAT':
        return DateTime.saturday;
      case 'SUN':
        return DateTime.sunday;
      default:
        return 0;
    }
  }

  @override
  List<Object?> get props => [id];
}

/// Konteks akademik yang ditampilkan di header halaman kalender.
///
/// Semua bagian bersifat opsional: bila user tidak punya izin
/// `tahun-ajaran.view` / `semester.view` / `hari-operasional.view`, bagian itu
/// dibiarkan null dan header hanya menampilkan yang tersedia.
class KalenderKonteksEntity extends Equatable {
  final TahunAjaranEntity? tahunAjaranAktif;
  final SemesterEntity? semesterAktif;
  final List<HariOperasionalEntity> hariOperasional;

  const KalenderKonteksEntity({
    this.tahunAjaranAktif,
    this.semesterAktif,
    this.hariOperasional = const [],
  });

  static const KalenderKonteksEntity kosong = KalenderKonteksEntity();

  bool get isKosong =>
      tahunAjaranAktif == null &&
      semesterAktif == null &&
      hariOperasional.isEmpty;

  /// Daftar weekday (1..7) yang aktif sebagai hari sekolah.
  List<int> get weekdayAktif =>
      hariOperasional
          .where((h) => h.isActive && h.weekday != 0)
          .map((h) => h.weekday)
          .toList()
        ..sort();

  @override
  List<Object?> get props => [tahunAjaranAktif, semesterAktif, hariOperasional];
}
