import '../../domain/entities/tunggakan_entity.dart';
import 'keuangan_json.dart';

/// Mapping dari `PembayaranSppService::rekapTunggakan()` (LIST).
/// Endpoint: `GET /keuangan/pembayaran-spp/siswa/{siswaId}/tunggakan`
class TunggakanModel {
  final int bulan;
  final int tahun;
  final double nominal;
  final double denda;
  final double dendaPersen;
  final int bulanTerlambat;
  final double total;

  const TunggakanModel({
    required this.bulan,
    required this.tahun,
    this.nominal = 0,
    this.denda = 0,
    this.dendaPersen = 0,
    this.bulanTerlambat = 0,
    this.total = 0,
  });

  factory TunggakanModel.fromJson(Map<String, dynamic> json) {
    return TunggakanModel(
      bulan: keuToIntOr(json['bulan']),
      tahun: keuToIntOr(json['tahun']),
      nominal: keuToDoubleOr(json['nominal']),
      denda: keuToDoubleOr(json['denda']),
      dendaPersen: keuToDoubleOr(json['denda_persen']),
      bulanTerlambat: keuToIntOr(json['bulan_terlambat']),
      total: keuToDoubleOr(json['total']),
    );
  }

  TunggakanEntity toEntity() => TunggakanEntity(
    bulan: bulan,
    tahun: tahun,
    nominal: nominal,
    denda: denda,
    dendaPersen: dendaPersen,
    bulanTerlambat: bulanTerlambat,
    total: total,
  );
}

/// Mapping dari `PembayaranSppService::hitungDendaKeterlambatan()` (OBJEK).
/// Endpoint: `GET /keuangan/pembayaran-spp/hitung-denda`
class DendaModel {
  final double nominal;
  final double denda;
  final double dendaPersen;
  final int bulanTerlambat;
  final double total;

  const DendaModel({
    this.nominal = 0,
    this.denda = 0,
    this.dendaPersen = 0,
    this.bulanTerlambat = 0,
    this.total = 0,
  });

  factory DendaModel.fromJson(Map<String, dynamic> json) {
    return DendaModel(
      nominal: keuToDoubleOr(json['nominal']),
      denda: keuToDoubleOr(json['denda']),
      dendaPersen: keuToDoubleOr(json['denda_persen']),
      bulanTerlambat: keuToIntOr(json['bulan_terlambat']),
      total: keuToDoubleOr(json['total']),
    );
  }

  DendaEntity toEntity() => DendaEntity(
    nominal: nominal,
    denda: denda,
    dendaPersen: dendaPersen,
    bulanTerlambat: bulanTerlambat,
    total: total,
  );
}
