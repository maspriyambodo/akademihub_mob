import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

/// Helper format khusus modul keuangan.
///
/// Sengaja TIDAK memakai `NumberFormat`/`DateFormat` dengan locale `id_ID`
/// karena `initializeDateFormatting()` tidak dipanggil di aplikasi ini —
/// semua format ditulis manual supaya aman.

const List<String> kNamaBulan = <String>[
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

const List<String> kNamaBulanSingkat = <String>[
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

String namaBulan(int? bulan) {
  if (bulan == null || bulan < 1 || bulan > 12) return '-';
  return kNamaBulan[bulan];
}

String namaBulanSingkat(int? bulan) {
  if (bulan == null || bulan < 1 || bulan > 12) return '-';
  return kNamaBulanSingkat[bulan];
}

/// Format rupiah manual: `1250000` → `Rp 1.250.000`.
/// Nilai desimal dibulatkan karena SPP selalu bilangan bulat rupiah.
String formatRupiah(num? nilai) {
  if (nilai == null) return 'Rp 0';
  final negatif = nilai < 0;
  final digits = nilai.abs().round().toString();

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negatif ? '-' : ''}Rp ${buffer.toString()}';
}

/// `8 Jan 2026`
String formatTanggal(DateTime? tanggal) {
  if (tanggal == null) return '-';
  return '${tanggal.day} ${namaBulanSingkat(tanggal.month)} ${tanggal.year}';
}

/// `8 Januari 2026`
String formatTanggalPanjang(DateTime? tanggal) {
  if (tanggal == null) return '-';
  return '${tanggal.day} ${namaBulan(tanggal.month)} ${tanggal.year}';
}

/// Persen tanpa desimal berlebih: `2.0` → `2%`, `2.5` → `2,5%`.
String formatPersen(double? nilai) {
  if (nilai == null) return '-';
  if (nilai == nilai.roundToDouble()) return '${nilai.round()}%';
  return '${nilai.toStringAsFixed(1).replaceAll('.', ',')}%';
}

/// Warna badge sesuai `PembayaranSppEntity.statusKey`.
Color warnaStatus(String statusKey) {
  switch (statusKey) {
    case 'lunas':
      return AppColors.success;
    case 'pending':
      return AppColors.warning;
    case 'batal':
      return AppColors.textSecondary;
    default:
      return AppColors.error;
  }
}

IconData ikonStatus(String statusKey) {
  switch (statusKey) {
    case 'lunas':
      return Icons.check_circle;
    case 'pending':
      return Icons.hourglass_top;
    case 'batal':
      return Icons.cancel_outlined;
    default:
      return Icons.error_outline;
  }
}

/// Badge status berwarna yang dipakai di daftar maupun halaman detail.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool besar;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.besar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: besar ? 160 : 130),
      padding: EdgeInsets.symmetric(
        horizontal: besar ? 12 : 8,
        vertical: besar ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: besar ? 14 : 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: besar ? 12 : 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip informasi kecil (kelas, NIS, metode bayar, dsb).
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris "label : nilai" untuk halaman detail.
class DetailRow extends StatelessWidget {
  final String label;
  final String nilai;
  final Color? warnaNilai;
  final bool tebal;

  const DetailRow({
    super.key,
    required this.label,
    required this.nilai,
    this.warnaNilai,
    this.tebal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            // Lebar label dipersempit di layar kecil supaya kolom nilai
            // (mis. nominal rupiah panjang) tetap punya ruang.
            width: Responsive.isCompact(context) ? 100 : 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: warnaNilai ?? AppColors.textPrimary,
                fontWeight: tebal ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
