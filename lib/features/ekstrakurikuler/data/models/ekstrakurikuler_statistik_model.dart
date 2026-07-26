import '../../domain/entities/ekstrakurikuler_statistik_entity.dart';

/// Model statistik peserta ekstrakurikuler.
class EkstrakurikulerStatistikModel {
  final int totalSiswa;
  final int totalSiswaAktif;
  final int totalSiswaKeluar;

  const EkstrakurikulerStatistikModel({
    this.totalSiswa = 0,
    this.totalSiswaAktif = 0,
    this.totalSiswaKeluar = 0,
  });

  factory EkstrakurikulerStatistikModel.fromJson(Map<String, dynamic> json) {
    final total = (json['total_siswa'] as num?)?.toInt() ?? 0;
    final aktif = (json['total_siswa_aktif'] as num?)?.toInt() ?? 0;
    return EkstrakurikulerStatistikModel(
      totalSiswa: total,
      totalSiswaAktif: aktif,
      totalSiswaKeluar:
          (json['total_siswa_keluar'] as num?)?.toInt() ?? (total - aktif),
    );
  }

  EkstrakurikulerStatistikEntity toEntity() => EkstrakurikulerStatistikEntity(
    totalSiswa: totalSiswa,
    totalSiswaAktif: totalSiswaAktif,
    totalSiswaKeluar: totalSiswaKeluar,
  );
}
