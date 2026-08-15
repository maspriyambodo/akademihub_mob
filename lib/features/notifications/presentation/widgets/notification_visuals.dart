import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_theme.dart';

/// Ikon, warna, dan label per tipe notifikasi.
class NotificationVisual {
  final IconData icon;
  final Color color;
  final String label;

  const NotificationVisual({
    required this.icon,
    required this.color,
    required this.label,
  });
}

/// Tipe yang benar-benar dipakai backend ada di
/// `App\Services\SmartNotificationService`:
/// `ews_alert`, `absensi`, `nilai_anomali`, `spp_tunggakan`,
/// `tugas_deadline`, `risk_profile`.
/// Beberapa alias umum ikut dipetakan, sisanya jatuh ke fallback.
NotificationVisual visualForType(String type) {
  switch (type.toLowerCase()) {
    case 'ews_alert':
      return const NotificationVisual(
        icon: Icons.warning_amber_rounded,
        color: AppColors.error,
        label: 'Peringatan Dini',
      );
    case 'absensi':
      return const NotificationVisual(
        icon: Icons.event_available_outlined,
        color: AppColors.info,
        label: 'Absensi',
      );
    case 'nilai_anomali':
    case 'nilai':
      return const NotificationVisual(
        icon: Icons.trending_down,
        color: AppColors.warning,
        label: 'Nilai',
      );
    case 'spp_tunggakan':
      return const NotificationVisual(
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.waliColor,
        label: 'Tunggakan SPP',
      );
    case 'tugas_deadline':
    case 'tugas':
      return const NotificationVisual(
        icon: Icons.assignment_outlined,
        color: AppColors.primary,
        label: 'Tugas',
      );
    case 'risk_profile':
      return const NotificationVisual(
        icon: Icons.report_problem_outlined,
        color: AppColors.error,
        label: 'Profil Risiko',
      );
    case 'pengumuman':
      return const NotificationVisual(
        icon: Icons.campaign_outlined,
        color: AppColors.accent,
        label: 'Pengumuman',
      );
    case 'jadwal':
      return const NotificationVisual(
        icon: Icons.calendar_today_outlined,
        color: AppColors.guruColor,
        label: 'Jadwal',
      );
    default:
      // Fallback ikon umum untuk tipe yang belum dikenali.
      return const NotificationVisual(
        icon: Icons.notifications_outlined,
        color: AppColors.textSecondary,
        label: 'Notifikasi',
      );
  }
}

/// Warna badge urgensi: `critical` | `high` | `medium` | `low`.
Color colorForUrgency(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'critical':
      return AppColors.error;
    case 'high':
      return const Color(0xFFEF6C00); // oranye
    case 'medium':
      return AppColors.warning;
    case 'low':
      return AppColors.success;
    default:
      return AppColors.textSecondary;
  }
}

String labelForUrgency(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'critical':
      return 'Kritis';
    case 'high':
      return 'Penting';
    case 'medium':
      return 'Sedang';
    case 'low':
      return 'Rendah';
    default:
      return urgency;
  }
}

// ── Waktu ───────────────────────────────────────────────────────────────────

bool _localeRegistered = false;

/// Daftarkan pesan locale Indonesia untuk `timeago`. Aman dipanggil berkali-kali
/// dan hanya berlaku untuk fitur ini (dipanggil dari halaman notifikasi).
void ensureTimeagoIdLocale() {
  if (_localeRegistered) return;
  timeago.setLocaleMessages('id', timeago.IdMessages());
  _localeRegistered = true;
}

/// Contoh hasil: "5 menit yang lalu".
String waktuRelatif(DateTime? date) {
  if (date == null) return '-';
  ensureTimeagoIdLocale();
  return timeago.format(date, locale: 'id');
}

/// Format absolut tanpa bergantung inisialisasi locale `intl`: "26/07/2026 14:05".
String waktuLengkap(DateTime? date) {
  if (date == null) return '-';
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final mi = date.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${date.year} $hh:$mi';
}
