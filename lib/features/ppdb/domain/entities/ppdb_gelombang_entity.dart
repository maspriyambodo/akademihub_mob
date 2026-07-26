import 'package:equatable/equatable.dart';

/// Gelombang pendaftaran PPDB.
///
/// Sumber: tabel `ppdb_gelombang` via `PpdbGelombangResource`
/// (endpoint `/ppdb/gelombang`). Tanggal berformat `Y-m-d` di jalur resource,
/// tetapi endpoint `show`/`active` mengembalikan model mentah (tanggal ISO) —
/// parsing di model menangani keduanya.
class PpdbGelombangEntity extends Equatable {
  final int id;
  final int? sekolahId;
  final String namaGelombang;

  /// Format `Y-m-d`, bisa kosong bila backend tidak mengirim.
  final String tglMulai;
  final String tglSelesai;

  final double? biayaPendaftaran;
  final bool isActive;

  /// Apakah hari ini berada dalam periode gelombang (hitungan backend bila
  /// tersedia via `is_active_period`, selain itu null).
  final bool? isActivePeriod;

  final int? kuotaTotal;
  final bool isSeleksiOtomatis;

  /// 1=manual, 2=saw, 3=weighted_rank.
  final int? metodeSeleksi;
  final String? metodeSeleksiLabel;
  final String? tahunAjaran;

  const PpdbGelombangEntity({
    required this.id,
    this.sekolahId,
    required this.namaGelombang,
    this.tglMulai = '',
    this.tglSelesai = '',
    this.biayaPendaftaran,
    this.isActive = false,
    this.isActivePeriod,
    this.kuotaTotal,
    this.isSeleksiOtomatis = false,
    this.metodeSeleksi,
    this.metodeSeleksiLabel,
    this.tahunAjaran,
  });

  @override
  List<Object?> get props => [id];
}
