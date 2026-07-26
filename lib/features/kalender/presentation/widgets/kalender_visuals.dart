import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/kalender_agenda_item.dart';
import '../../domain/entities/kalender_tipe_entity.dart';

/// Helper format tanggal & visual untuk modul kalender.
///
/// Sengaja TIDAK memakai `intl` dengan locale `id_ID`: locale date formatting
/// belum di-init di aplikasi ini, jadi nama bulan/hari ditulis manual.

const List<String> namaBulanPanjang = [
  '',
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> namaBulanPendek = [
  '',
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

const List<String> namaHariPanjang = [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> namaHariPendek = [
  '',
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

String labelBulan(int bulan) =>
    (bulan >= 1 && bulan <= 12) ? namaBulanPanjang[bulan] : '-';

String labelBulanPendek(int bulan) =>
    (bulan >= 1 && bulan <= 12) ? namaBulanPendek[bulan] : '-';

String labelHari(int weekday) =>
    (weekday >= 1 && weekday <= 7) ? namaHariPanjang[weekday] : '';

String labelHariPendek(int weekday) =>
    (weekday >= 1 && weekday <= 7) ? namaHariPendek[weekday] : '';

/// "Senin, 14 Juli 2026"
String formatTanggalPanjang(DateTime d) =>
    '${labelHari(d.weekday)}, ${d.day} ${labelBulan(d.month)} ${d.year}';

/// "14 Jul 2026"
String formatTanggalPendek(DateTime d) =>
    '${d.day} ${labelBulanPendek(d.month)} ${d.year}';

/// Rentang tanggal yang ringkas:
/// - satu hari        → "14 Jul 2026"
/// - dalam satu bulan → "14 – 18 Jul 2026"
/// - lintas bulan     → "28 Jul – 3 Agu 2026"
/// - lintas tahun     → "28 Des 2026 – 3 Jan 2027"
String formatRentangTanggal(DateTime mulai, DateTime? selesai) {
  if (selesai == null || !selesai.isAfter(mulai)) {
    return formatTanggalPendek(mulai);
  }
  if (mulai.year == selesai.year && mulai.month == selesai.month) {
    return '${mulai.day} – ${selesai.day} '
        '${labelBulanPendek(mulai.month)} ${mulai.year}';
  }
  if (mulai.year == selesai.year) {
    return '${mulai.day} ${labelBulanPendek(mulai.month)} – '
        '${selesai.day} ${labelBulanPendek(selesai.month)} ${mulai.year}';
  }
  return '${formatTanggalPendek(mulai)} – ${formatTanggalPendek(selesai)}';
}

/// "07:30 – 09:00" / "07:30" / "" (kosong bila all-day atau tanpa jam).
String formatRentangWaktu(String? mulai, String? selesai) {
  if (mulai == null && selesai == null) return '';
  if (mulai != null && selesai != null) return '$mulai – $selesai';
  return mulai ?? selesai ?? '';
}

/// Selisih hari dari hari ini → label relatif tanpa dependensi locale.
String labelRelatif(DateTime target, DateTime hariIni) {
  final a = DateTime(target.year, target.month, target.day);
  final b = DateTime(hariIni.year, hariIni.month, hariIni.day);
  final selisih = a.difference(b).inDays;
  if (selisih == 0) return 'Hari ini';
  if (selisih == 1) return 'Besok';
  if (selisih == 2) return 'Lusa';
  if (selisih == -1) return 'Kemarin';
  if (selisih > 0) return '$selisih hari lagi';
  return '${-selisih} hari lalu';
}

/// Mengubah string warna backend (mis. `#ef4444`, `ef4444`, `#fef4444f`)
/// menjadi [Color]. Mengembalikan null bila tidak dapat diurai.
Color? parseWarnaHex(String? hex) {
  if (hex == null) return null;
  var s = hex.trim().replaceAll('#', '');
  if (s.length == 3) {
    s = s.split('').map((c) => '$c$c').join();
  }
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final nilai = int.tryParse(s, radix: 16);
  return nilai == null ? null : Color(nilai);
}

/// Warna chip kategori. Prioritas: `warna` dari backend → warna semantik
/// berdasarkan flag tipe → abu-abu netral.
Color warnaTipe(KalenderTipeEntity? tipe) {
  final dariBackend = parseWarnaHex(tipe?.warna);
  if (dariBackend != null) return dariBackend;
  if (tipe == null) return AppColors.textSecondary;
  if (tipe.isUjian) return AppColors.error;
  if (tipe.isLibur) return AppColors.success;
  if (tipe.isPenting) return AppColors.warning;
  return AppColors.primary;
}

/// Backend tidak menyimpan ikon untuk tipe kalender, jadi ikon diturunkan
/// dari flag `is_ujian` / `is_libur` / `is_penting` dan `kode`.
IconData ikonTipe(KalenderTipeEntity? tipe) {
  if (tipe == null) return Icons.event_note_outlined;
  final kode = tipe.kode.toUpperCase();
  if (kode.contains('LIBUR')) return Icons.beach_access_outlined;
  if (kode.contains('UTS') || kode.contains('UAS') || kode.contains('UJIAN')) {
    return Icons.fact_check_outlined;
  }
  if (kode.contains('TES')) return Icons.edit_note_outlined;
  if (kode.contains('KEGIATAN')) return Icons.groups_outlined;
  if (tipe.isUjian) return Icons.fact_check_outlined;
  if (tipe.isLibur) return Icons.beach_access_outlined;
  if (tipe.isPenting) return Icons.priority_high_rounded;
  return Icons.event_note_outlined;
}

/// Label status event (0 = dibatalkan, 1 = aktif, 2 = selesai).
String? labelStatus(int status) {
  switch (status) {
    case 0:
      return 'Dibatalkan';
    case 2:
      return 'Selesai';
    default:
      return null;
  }
}

Color warnaStatus(int status) {
  switch (status) {
    case 0:
      return AppColors.error;
    case 2:
      return AppColors.textSecondary;
    default:
      return AppColors.success;
  }
}

/// Label prioritas (1 = tinggi, 2 = normal, 3 = rendah).
String? labelPrioritas(int prioritas) {
  switch (prioritas) {
    case 1:
      return 'Prioritas tinggi';
    case 3:
      return 'Prioritas rendah';
    default:
      return null;
  }
}

/// Label sumber data untuk membedakan asal baris pada linimasa gabungan.
String labelSumber(KalenderSumber sumber) =>
    sumber == KalenderSumber.harian ? 'Agenda Harian' : 'Kalender Akademik';

Color warnaSumber(KalenderSumber sumber) =>
    sumber == KalenderSumber.harian ? AppColors.secondary : AppColors.primary;

IconData ikonSumber(KalenderSumber sumber) => sumber == KalenderSumber.harian
    ? Icons.today_outlined
    : Icons.calendar_month_outlined;
