import '../../domain/entities/laporan_periode_entity.dart';
import 'keuangan_json.dart';

/// Mapping dari `PembayaranSppService::getLaporanKeuanganPeriode()`.
/// Endpoint: `GET /keuangan/pembayaran-spp/laporan-periode`
///
/// `data` berupa OBJEK dengan 4 kunci:
/// ```json
/// {
///   "filter": {"tahun":2026,"bulan_dari":1,"bulan_sampai":12,
///              "nama_bulan_dari":"Januari","nama_bulan_sampai":"Desember",
///              "mst_kelas_id":null,"tahun_ajaran_id":null},
///   "ringkasan": {"total_pendapatan":0,"total_transaksi":0,
///                 "rata_rata_per_bulan":0},
///   "per_bulan": [{"bulan":1,"nama_bulan":"Januari","tahun":2026,
///                  "total_pendapatan":0,"jumlah_lunas":0,
///                  "jumlah_belum_lunas":0,"total_transaksi":0}],
///   "per_kelas": [{"kelas_id":5,"nama_kelas":"X IPA 1","jumlah_siswa":0,
///                  "total_pendapatan":0,"jumlah_lunas":0,
///                  "jumlah_belum_lunas":0,"total_transaksi":0}]
/// }
/// ```
class LaporanPeriodeModel {
  final int tahun;
  final int bulanDari;
  final int bulanSampai;
  final String? namaBulanDari;
  final String? namaBulanSampai;
  final double totalPendapatan;
  final int totalTransaksi;
  final double rataRataPerBulan;
  final List<LaporanBulanEntity> perBulan;
  final List<LaporanKelasEntity> perKelas;

  const LaporanPeriodeModel({
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

  factory LaporanPeriodeModel.fromJson(Map<String, dynamic> json) {
    final filter = keuToMap(json['filter']) ?? const <String, dynamic>{};
    final ringkasan = keuToMap(json['ringkasan']) ?? const <String, dynamic>{};

    return LaporanPeriodeModel(
      tahun: keuToIntOr(filter['tahun'], DateTime.now().year),
      bulanDari: keuToIntOr(filter['bulan_dari'], 1),
      bulanSampai: keuToIntOr(filter['bulan_sampai'], 12),
      namaBulanDari: keuToText(filter['nama_bulan_dari']),
      namaBulanSampai: keuToText(filter['nama_bulan_sampai']),
      totalPendapatan: keuToDoubleOr(ringkasan['total_pendapatan']),
      totalTransaksi: keuToIntOr(ringkasan['total_transaksi']),
      rataRataPerBulan: keuToDoubleOr(ringkasan['rata_rata_per_bulan']),
      perBulan: keuToMapList(json['per_bulan'])
          .map(
            (m) => LaporanBulanEntity(
              bulan: keuToIntOr(m['bulan']),
              namaBulan: keuToText(m['nama_bulan']),
              tahun: keuToInt(m['tahun']),
              totalPendapatan: keuToDoubleOr(m['total_pendapatan']),
              jumlahLunas: keuToIntOr(m['jumlah_lunas']),
              jumlahBelumLunas: keuToIntOr(m['jumlah_belum_lunas']),
              totalTransaksi: keuToIntOr(m['total_transaksi']),
            ),
          )
          .toList(),
      perKelas: keuToMapList(json['per_kelas'])
          .map(
            (m) => LaporanKelasEntity(
              kelasId: keuToInt(m['kelas_id']),
              namaKelas: keuToText(m['nama_kelas']),
              jumlahSiswa: keuToIntOr(m['jumlah_siswa']),
              totalPendapatan: keuToDoubleOr(m['total_pendapatan']),
              jumlahLunas: keuToIntOr(m['jumlah_lunas']),
              jumlahBelumLunas: keuToIntOr(m['jumlah_belum_lunas']),
              totalTransaksi: keuToIntOr(m['total_transaksi']),
            ),
          )
          .toList(),
    );
  }

  LaporanPeriodeEntity toEntity() => LaporanPeriodeEntity(
    tahun: tahun,
    bulanDari: bulanDari,
    bulanSampai: bulanSampai,
    namaBulanDari: namaBulanDari,
    namaBulanSampai: namaBulanSampai,
    totalPendapatan: totalPendapatan,
    totalTransaksi: totalTransaksi,
    rataRataPerBulan: rataRataPerBulan,
    perBulan: perBulan,
    perKelas: perKelas,
  );
}
