import 'package:equatable/equatable.dart';

/// Satu baris pembayaran / tagihan SPP.
///
/// Backend: `TrxPembayaranSpp` + `PembayaranSppResource`
/// (`app/Http/Resources/Api/V1/PembayaranSppResource.php`).
///
/// Endpoint:
/// - `GET /keuangan/pembayaran-spp`            (index, terpaginasi)
/// - `GET /keuangan/pembayaran-spp/{id}`       (show)
/// - `GET /keuangan/pembayaran-spp/siswa/{id}` (riwayat per siswa)
///
/// Catatan penting soal `status` & `metode_pembayaran`: di database keduanya
/// bertipe `smallint` (ref `sys_references`), tetapi Resource mengubahnya jadi
/// LABEL string lewat `refLabel()`. Jadi yang sampai ke aplikasi adalah
/// `"Lunas" | "Belum Lunas" | "Pending" | "Batal"` dan
/// `"Tunai" | "Transfer" | "Virtual Account" | ...`.
/// Bila baris `sys_references` tidak ada, Resource mengembalikan angkanya
/// sebagai string ("1".."4") — makanya normalisasi di bawah menangani keduanya.
class PembayaranSppEntity extends Equatable {
  final int id;

  /// `siswa.id` — hanya terisi bila relasi siswa di-eager-load
  /// (index & show: ya, endpoint by-siswa: tidak, karena hanya `tarifSpp.kelas`).
  final int? siswaId;

  /// `siswa.nama`
  final String? siswaNama;

  /// `siswa.nis`
  final String? siswaNis;

  /// `tarif_spp.id`
  final int? tarifSppId;

  /// `tarif_spp.nominal` — nominal tarif SPP per bulan.
  final double? tarifNominal;

  /// `tarif_spp.kelas.id`
  final int? kelasId;

  /// `tarif_spp.kelas.nama_kelas`
  final String? kelasNama;

  /// `bulan` (1..12)
  final int? bulan;

  /// `nama_bulan` — accessor Eloquent, mis. "Januari".
  final String? namaBulan;

  /// `tahun`
  final int? tahun;

  /// `tanggal_bayar` — dikirim backend dengan format `Y-m-d`.
  final DateTime? tanggalBayar;

  /// `jumlah_bayar` — dikirim sebagai string desimal ("350000.00").
  final double? jumlahBayar;

  /// `status` — label dari `sys_references.status_bayar`.
  final String? status;

  /// `metode_pembayaran` — label dari `sys_references.metode_pembayaran`.
  final String? metodePembayaran;

  /// `keterangan` — catatan bebas / bukti pembayaran dalam bentuk teks.
  final String? keterangan;

  /// `petugas.id`
  final int? petugasId;

  /// `petugas.name`
  final String? petugasNama;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PembayaranSppEntity({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.tarifSppId,
    this.tarifNominal,
    this.kelasId,
    this.kelasNama,
    this.bulan,
    this.namaBulan,
    this.tahun,
    this.tanggalBayar,
    this.jumlahBayar,
    this.status,
    this.metodePembayaran,
    this.keterangan,
    this.petugasId,
    this.petugasNama,
    this.createdAt,
    this.updatedAt,
  });

  /// Normalisasi status ke kunci internal supaya aman baik saat backend
  /// mengirim label ("Lunas") maupun kode mentah ("1").
  String get statusKey {
    final raw = status?.trim().toLowerCase() ?? '';
    switch (raw) {
      case '1':
        return 'lunas';
      case '2':
        return 'belum lunas';
      case '3':
        return 'pending';
      case '4':
        return 'batal';
      default:
        return raw;
    }
  }

  bool get isLunas => statusKey == 'lunas';
  bool get isPending => statusKey == 'pending';
  bool get isBatal => statusKey == 'batal';
  bool get isBelumLunas => !isLunas && !isPending && !isBatal;

  /// Label status siap tampil (fallback bila backend mengirim null/kode).
  String get statusLabel {
    switch (statusKey) {
      case 'lunas':
        return 'Lunas';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'batal':
        return 'Batal';
      case 'belum lunas':
      case '':
        return 'Belum Lunas';
      default:
        return status!;
    }
  }

  /// Judul kartu, mis. "Januari 2026".
  String get labelPeriode {
    final b = (namaBulan != null && namaBulan!.isNotEmpty && namaBulan != '-')
        ? namaBulan!
        : (bulan?.toString() ?? '-');
    return tahun != null ? '$b $tahun' : b;
  }

  /// Nominal yang dipakai untuk perhitungan: pakai `jumlah_bayar` bila ada,
  /// bila tidak jatuh ke nominal tarif.
  double get nominalEfektif => jumlahBayar ?? tarifNominal ?? 0;

  /// Data cukup lengkap untuk memicu pembayaran online / pencatatan bayar.
  bool get bisaDibayar =>
      siswaId != null && tarifSppId != null && bulan != null && tahun != null;

  @override
  List<Object?> get props => [id];
}
