import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/peminjaman_buku_entity.dart';

/// Nama bulan ditulis manual supaya tidak bergantung pada
/// `initializeDateFormatting('id_ID')` yang belum dipanggil di aplikasi ini.
const List<String> _bulanSingkat = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// "2026-07-20" → "20 Jul 2026". Mengembalikan [kosong] bila tidak terbaca.
String formatTanggal(String? raw, {String kosong = '-'}) {
  if (raw == null || raw.isEmpty) return kosong;
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  return formatTanggalDate(dt);
}

String formatTanggalDate(DateTime dt) =>
    '${dt.day} ${_bulanSingkat[dt.month - 1]} ${dt.year}';

/// Format yang diminta backend untuk field tanggal (`YYYY-MM-DD`).
String formatTanggalApi(DateTime dt) {
  String dua(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${dua(dt.month)}-${dua(dt.day)}';
}

/// Teks sisa/kelebihan waktu untuk peminjaman yang masih berjalan.
String? teksTenggat(PeminjamanBukuEntity item, {required bool terlambat}) {
  if (item.sudahDikembalikan || item.hilang) return null;

  final sisa = item.sisaHari;
  if (sisa == null) {
    return terlambat ? 'Terlambat' : null;
  }
  if (sisa < 0) return 'Terlambat ${-sisa} hari';
  if (sisa == 0) return 'Jatuh tempo hari ini';
  if (sisa == 1) return 'Sisa 1 hari';
  return 'Sisa $sisa hari';
}

/// Warna status untuk kartu peminjaman.
Color warnaStatus(PeminjamanBukuEntity item, {required bool terlambat}) {
  if (item.hilang) return AppColors.error;
  if (item.sudahDikembalikan) {
    return item.dikembalikanTerlambat ? AppColors.warning : AppColors.success;
  }
  if (terlambat) return AppColors.error;

  final sisa = item.sisaHari;
  if (sisa != null && sisa <= 2) return AppColors.warning;
  return AppColors.info;
}

/// Warna indikator ketersediaan buku.
Color warnaKetersediaan(int stok) {
  if (stok <= 0) return AppColors.error;
  if (stok <= 2) return AppColors.warning;
  return AppColors.success;
}

/// Teks ketersediaan. [total] hanya tersedia di halaman detail karena
/// `BukuResource` tidak mengirim jumlah eksemplar keseluruhan.
String teksKetersediaan(int stok, {int? total}) {
  if (total != null && total > 0) return '$stok dari $total tersedia';
  if (stok <= 0) return 'Stok habis';
  return '$stok eksemplar tersedia';
}
