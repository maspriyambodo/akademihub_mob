import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Helper visual & format untuk modul PPDB.
///
/// Format tanggal/uang ditulis manual (tanpa `initializeDateFormatting`)
/// mengikuti pola fitur absensi/jadwal.

const List<String> _namaBulan = [
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

/// `2026-07-01` → `1 Jul 2026`. String kosong / tak valid → `-`.
String formatTanggalPpdb(String? tanggal) {
  if (tanggal == null || tanggal.isEmpty) return '-';
  final d = DateTime.tryParse(
    tanggal.length >= 10 ? tanggal.substring(0, 10) : tanggal,
  );
  if (d == null) return tanggal;
  return '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';
}

/// 1250000.0 → `Rp 1.250.000`.
String formatRupiah(double? nilai) {
  if (nilai == null) return '-';
  final bulat = nilai.round();
  final digits = bulat.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${bulat < 0 ? '-' : ''}Rp $buffer';
}

/// Angka nilai (85.5 → `85,5`; 85.0 → `85`).
String formatNilai(double? nilai) {
  if (nilai == null) return '-';
  if (nilai == nilai.roundToDouble()) return nilai.round().toString();
  return nilai.toStringAsFixed(2).replaceAll('.', ',');
}

// ── Status pendaftaran ────────────────────────────────────────────────────────

Color warnaStatusPendaftaran(String status) {
  switch (status) {
    case 'draft':
      return AppColors.textSecondary;
    case 'terverifikasi':
      return AppColors.info;
    case 'seleksi':
      return AppColors.warning;
    case 'diterima':
      return AppColors.success;
    case 'cadangan':
      return AppColors.accent;
    case 'ditolak':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

String labelStatusPendaftaran(String status) {
  switch (status) {
    case 'draft':
      return 'Draft';
    case 'terverifikasi':
      return 'Terverifikasi';
    case 'seleksi':
      return 'Seleksi';
    case 'diterima':
      return 'Diterima';
    case 'cadangan':
      return 'Cadangan';
    case 'ditolak':
      return 'Ditolak';
    default:
      return status;
  }
}

IconData ikonStatusPendaftaran(String status) {
  switch (status) {
    case 'draft':
      return Icons.edit_note_outlined;
    case 'terverifikasi':
      return Icons.verified_outlined;
    case 'seleksi':
      return Icons.hourglass_top_outlined;
    case 'diterima':
      return Icons.check_circle_outline;
    case 'cadangan':
      return Icons.bookmark_border;
    case 'ditolak':
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline;
  }
}

// ── Status seleksi otomatis (enum backend PpdbStatusSeleksi) ──────────────────

Color warnaStatusSeleksi(String status) {
  switch (status) {
    case 'lolos':
      return AppColors.success;
    case 'cadangan':
      return AppColors.accent;
    case 'tidak_lolos':
      return AppColors.error;
    case 'menunggu':
    default:
      return AppColors.warning;
  }
}

String labelStatusSeleksi(String status) {
  switch (status) {
    case 'lolos':
      return 'Lolos Seleksi';
    case 'cadangan':
      return 'Cadangan';
    case 'tidak_lolos':
      return 'Tidak Lolos';
    case 'menunggu':
      return 'Menunggu';
    default:
      return status;
  }
}

// ── Jenis dokumen ─────────────────────────────────────────────────────────────

String labelJenisDokumen(String jenis) {
  switch (jenis.toLowerCase()) {
    case 'kartukeluarga':
      return 'Kartu Keluarga';
    case 'akte':
      return 'Akte Kelahiran';
    case 'rapor':
      return 'Rapor';
    case 'ijazah':
      return 'Ijazah';
    default:
      return jenis.isEmpty ? 'Dokumen' : jenis;
  }
}

IconData ikonJenisDokumen(String jenis) {
  switch (jenis.toLowerCase()) {
    case 'kartukeluarga':
      return Icons.family_restroom_outlined;
    case 'akte':
      return Icons.badge_outlined;
    case 'rapor':
      return Icons.menu_book_outlined;
    case 'ijazah':
      return Icons.workspace_premium_outlined;
    default:
      return Icons.description_outlined;
  }
}

/// `1536000` → `1,5 MB`.
String formatUkuranFile(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
}

// ── Widget kecil bersama ──────────────────────────────────────────────────────

/// Chip status berwarna (dipakai di kartu daftar & halaman detail).
class PpdbStatusChip extends StatelessWidget {
  final String label;
  final Color warna;
  final IconData? ikon;

  const PpdbStatusChip({
    super.key,
    required this.label,
    required this.warna,
    this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warna.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 12, color: warna),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
