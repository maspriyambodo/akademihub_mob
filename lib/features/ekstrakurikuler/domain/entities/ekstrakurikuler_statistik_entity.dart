import 'package:equatable/equatable.dart';

/// Statistik peserta satu ekstrakurikuler.
///
/// Dikembalikan `GET /ekstrakurikuler/{id}/statistik` dengan bentuk
/// `{ "total_siswa": n, "total_siswa_aktif": n, "total_siswa_keluar": n }`.
///
/// Catatan: tabel `mst_ekstrakurikuler` TIDAK punya kolom kuota/daya tampung,
/// sehingga tidak ada angka "terisi dari total kuota" yang bisa ditampilkan.
class EkstrakurikulerStatistikEntity extends Equatable {
  final int totalSiswa;
  final int totalSiswaAktif;
  final int totalSiswaKeluar;

  const EkstrakurikulerStatistikEntity({
    this.totalSiswa = 0,
    this.totalSiswaAktif = 0,
    this.totalSiswaKeluar = 0,
  });

  @override
  List<Object?> get props => [totalSiswa, totalSiswaAktif, totalSiswaKeluar];
}
