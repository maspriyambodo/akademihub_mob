import 'package:equatable/equatable.dart';

/// Statistik jumlah pendaftar per status.
///
/// Sumber utama: `GET /ppdb/pendaftaran/sekolah/{sekolahId}/statistics`
/// (`PpdbPendaftaranService::getStatistics`). Bila `sekolah_id` tidak dapat
/// ditentukan, statistik dihitung di sisi klien dari daftar yang dimuat
/// (`dariServer = false`).
class PpdbStatistikEntity extends Equatable {
  final int total;
  final int draft;
  final int terverifikasi;
  final int seleksi;
  final int diterima;
  final int cadangan;
  final int ditolak;

  /// `true` bila angka berasal dari endpoint statistik backend,
  /// `false` bila dihitung klien dari daftar yang termuat.
  final bool dariServer;

  const PpdbStatistikEntity({
    this.total = 0,
    this.draft = 0,
    this.terverifikasi = 0,
    this.seleksi = 0,
    this.diterima = 0,
    this.cadangan = 0,
    this.ditolak = 0,
    this.dariServer = false,
  });

  static const kosong = PpdbStatistikEntity();

  int jumlahUntuk(String status) {
    switch (status) {
      case 'draft':
        return draft;
      case 'terverifikasi':
        return terverifikasi;
      case 'seleksi':
        return seleksi;
      case 'diterima':
        return diterima;
      case 'cadangan':
        return cadangan;
      case 'ditolak':
        return ditolak;
      default:
        return 0;
    }
  }

  @override
  List<Object?> get props => [
    total,
    draft,
    terverifikasi,
    seleksi,
    diterima,
    cadangan,
    ditolak,
    dariServer,
  ];
}
