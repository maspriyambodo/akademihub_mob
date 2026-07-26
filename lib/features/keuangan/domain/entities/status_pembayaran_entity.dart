import 'package:equatable/equatable.dart';

/// Ringkasan status pembayaran SPP satu siswa dalam satu tahun ajaran.
///
/// Backend: `PembayaranSppService::getStatusPembayaranSiswa()`.
/// Endpoint: `GET /keuangan/pembayaran-spp/siswa/{siswaId}/status`
/// (query opsional `tahun_ajaran`, default `YYYY/YYYY+1`).
///
/// Bentuk response BUKAN list, melainkan objek:
/// ```json
/// {
///   "tahun_ajaran": "2026/2027",
///   "total_bulan": 12,
///   "lunas": 5,
///   "belum_lunas": 3,
///   "bulan_lunas": [1,2,3,4,5],
///   "bulan_belum_lunas": {"5":6,"6":7,...}
/// }
/// ```
/// Perhatian: `bulan_belum_lunas` dibuat dengan `array_diff()` di PHP sehingga
/// key-nya tidak berurutan → json_encode menghasilkan OBJEK, bukan array.
/// Parser di layer data menangani kedua bentuk.
///
/// Perhatian kedua: `belum_lunas` menghitung jumlah RECORD berstatus bukan
/// lunas, sedangkan `bulan_belum_lunas` berisi semua bulan yang belum lunas
/// (termasuk bulan yang belum jatuh tempo). Kedua angka ini memang bisa beda.
class StatusPembayaranEntity extends Equatable {
  final String? tahunAjaran;
  final int totalBulan;

  /// Jumlah bulan yang sudah lunas.
  final int lunas;

  /// Jumlah record pembayaran berstatus bukan lunas.
  final int belumLunas;

  final List<int> bulanLunas;
  final List<int> bulanBelumLunas;

  const StatusPembayaranEntity({
    this.tahunAjaran,
    this.totalBulan = 12,
    this.lunas = 0,
    this.belumLunas = 0,
    this.bulanLunas = const [],
    this.bulanBelumLunas = const [],
  });

  bool sudahLunasBulan(int bulan) => bulanLunas.contains(bulan);

  /// Proporsi bulan lunas (0..1) untuk progress bar.
  double get progres {
    if (totalBulan <= 0) return 0;
    final rasio = lunas / totalBulan;
    if (rasio < 0) return 0;
    if (rasio > 1) return 1;
    return rasio;
  }

  @override
  List<Object?> get props => [
    tahunAjaran,
    totalBulan,
    lunas,
    belumLunas,
    bulanLunas,
    bulanBelumLunas,
  ];
}
