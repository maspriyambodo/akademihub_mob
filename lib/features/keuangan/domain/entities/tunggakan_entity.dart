import 'package:equatable/equatable.dart';

/// Satu bulan tunggakan beserta kalkulasi dendanya.
///
/// Backend: `PembayaranSppService::rekapTunggakan()`.
/// Endpoint: `GET /keuangan/pembayaran-spp/siswa/{siswaId}/tunggakan`
/// dengan query WAJIB `tarif_spp_id` dan `tahun`.
///
/// Response `data` berupa LIST objek:
/// ```json
/// [{"bulan":1,"tahun":2026,"nominal":350000,"denda":7000,
///   "denda_persen":2,"bulan_terlambat":1,"total":357000}]
/// ```
/// Bulan yang belum jatuh tempo (tanggal 10 tiap bulan, dari
/// `sys_references.spp_config`) tidak ikut dihitung sebagai tunggakan.
class TunggakanEntity extends Equatable {
  final int bulan;
  final int tahun;

  /// Nominal tarif SPP bulan tersebut.
  final double nominal;

  /// Denda keterlambatan.
  final double denda;

  /// Persen denda kumulatif (bulan_terlambat × persen per bulan).
  final double dendaPersen;

  /// Jumlah bulan keterlambatan.
  final int bulanTerlambat;

  /// `nominal + denda`.
  final double total;

  const TunggakanEntity({
    required this.bulan,
    required this.tahun,
    this.nominal = 0,
    this.denda = 0,
    this.dendaPersen = 0,
    this.bulanTerlambat = 0,
    this.total = 0,
  });

  bool get adaDenda => denda > 0;

  @override
  List<Object?> get props => [bulan, tahun];
}

/// Hasil `GET /keuangan/pembayaran-spp/hitung-denda`.
///
/// Query param yang diterima controller (semua divalidasi):
/// - `tarif_spp_id` (wajib, exists:mst_tarif_spp,id)
/// - `bulan` (wajib, 1..12)
/// - `tahun` (wajib, >= 2020)
/// - `tanggal_bayar` (opsional, date — default: hari ini)
///
/// Response `data` BUKAN list, melainkan satu objek:
/// `{"nominal":..,"denda":..,"denda_persen":..,"bulan_terlambat":..,"total":..}`
class DendaEntity extends Equatable {
  final double nominal;
  final double denda;
  final double dendaPersen;
  final int bulanTerlambat;
  final double total;

  const DendaEntity({
    this.nominal = 0,
    this.denda = 0,
    this.dendaPersen = 0,
    this.bulanTerlambat = 0,
    this.total = 0,
  });

  bool get adaDenda => denda > 0;

  @override
  List<Object?> get props => [
    nominal,
    denda,
    dendaPersen,
    bulanTerlambat,
    total,
  ];
}
