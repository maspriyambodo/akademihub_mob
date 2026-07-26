import 'package:equatable/equatable.dart';

/// Rekap satu bulan pada laporan periode.
class LaporanBulanEntity extends Equatable {
  final int bulan;
  final String? namaBulan;
  final int? tahun;
  final double totalPendapatan;
  final int jumlahLunas;
  final int jumlahBelumLunas;
  final int totalTransaksi;

  const LaporanBulanEntity({
    required this.bulan,
    this.namaBulan,
    this.tahun,
    this.totalPendapatan = 0,
    this.jumlahLunas = 0,
    this.jumlahBelumLunas = 0,
    this.totalTransaksi = 0,
  });

  @override
  List<Object?> get props => [bulan, tahun];
}

/// Rekap satu kelas pada laporan periode.
class LaporanKelasEntity extends Equatable {
  final int? kelasId;
  final String? namaKelas;
  final int jumlahSiswa;
  final double totalPendapatan;
  final int jumlahLunas;
  final int jumlahBelumLunas;
  final int totalTransaksi;

  const LaporanKelasEntity({
    this.kelasId,
    this.namaKelas,
    this.jumlahSiswa = 0,
    this.totalPendapatan = 0,
    this.jumlahLunas = 0,
    this.jumlahBelumLunas = 0,
    this.totalTransaksi = 0,
  });

  @override
  List<Object?> get props => [kelasId, namaKelas];
}

/// Laporan keuangan SPP per periode (khusus admin/petugas).
///
/// Backend: `PembayaranSppService::getLaporanKeuanganPeriode()`.
/// Endpoint: `GET /keuangan/pembayaran-spp/laporan-periode`
/// Query opsional: `tahun`, `bulan_dari`, `bulan_sampai`, `mst_kelas_id`,
/// `tahun_ajaran_id`.
///
/// Response `data` BUKAN list, melainkan objek dengan 4 kunci:
/// `filter`, `ringkasan`, `per_bulan`, `per_kelas`.
class LaporanPeriodeEntity extends Equatable {
  final int tahun;
  final int bulanDari;
  final int bulanSampai;
  final String? namaBulanDari;
  final String? namaBulanSampai;

  /// `ringkasan.total_pendapatan`
  final double totalPendapatan;

  /// `ringkasan.total_transaksi`
  final int totalTransaksi;

  /// `ringkasan.rata_rata_per_bulan`
  final double rataRataPerBulan;

  final List<LaporanBulanEntity> perBulan;
  final List<LaporanKelasEntity> perKelas;

  const LaporanPeriodeEntity({
    required this.tahun,
    this.bulanDari = 1,
    this.bulanSampai = 12,
    this.namaBulanDari,
    this.namaBulanSampai,
    this.totalPendapatan = 0,
    this.totalTransaksi = 0,
    this.rataRataPerBulan = 0,
    this.perBulan = const [],
    this.perKelas = const [],
  });

  @override
  List<Object?> get props => [
    tahun,
    bulanDari,
    bulanSampai,
    totalPendapatan,
    totalTransaksi,
  ];
}
