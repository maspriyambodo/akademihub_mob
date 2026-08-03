import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_theme.dart';

// ── Waktu ───────────────────────────────────────────────────────────────────

bool _localeTerdaftar = false;

/// Daftarkan pesan locale Indonesia untuk `timeago`.
/// Idempoten dan lokal untuk fitur forum (tidak mengimpor lintas fitur).
void ensureTimeagoIdLocale() {
  if (_localeTerdaftar) return;
  timeago.setLocaleMessages('id', timeago.IdMessages());
  _localeTerdaftar = true;
}

/// Contoh hasil: "5 menit yang lalu".
String waktuRelatif(DateTime? date) {
  if (date == null) return '-';
  ensureTimeagoIdLocale();
  return timeago.format(date, locale: 'id');
}

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

/// Format absolut tanpa bergantung inisialisasi locale `intl`:
/// "26 Jul 2026, 14:05".
String waktuLengkap(DateTime? date) {
  if (date == null) return '-';
  final bulan = _namaBulan[date.month - 1];
  final hh = date.hour.toString().padLeft(2, '0');
  final mi = date.minute.toString().padLeft(2, '0');
  return '${date.day} $bulan ${date.year}, $hh:$mi';
}

// ── Tipe post (`trx_forum.tipe`) ────────────────────────────────────────────

/// 1 = discussion, 2 = question, 3 = announcement (lihat komentar migrasi
/// `2025_01_01_000070_create_trx_forum_table.php`).
class ForumTipe {
  final int nilai;
  final String label;
  final IconData icon;
  final Color color;

  const ForumTipe({
    required this.nilai,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<ForumTipe> forumTipeOptions = [
  ForumTipe(
    nilai: 1,
    label: 'Diskusi',
    icon: Icons.forum_outlined,
    color: AppColors.primary,
  ),
  ForumTipe(
    nilai: 2,
    label: 'Pertanyaan',
    icon: Icons.help_outline,
    color: AppColors.info,
  ),
  ForumTipe(
    nilai: 3,
    label: 'Pengumuman',
    icon: Icons.campaign_outlined,
    color: AppColors.accent,
  ),
];

ForumTipe forumTipeOf(int? nilai) {
  for (final t in forumTipeOptions) {
    if (t.nilai == nilai) return t;
  }
  return forumTipeOptions.first;
}

// ── Status post (`trx_forum.status`) ────────────────────────────────────────

/// 0 = closed, 1 = open, 2 = pinned.
String forumStatusLabel(int? status) {
  switch (status) {
    case 0:
      return 'Ditutup';
    case 2:
      return 'Disematkan';
    default:
      return 'Terbuka';
  }
}

Color forumStatusColor(int? status) {
  switch (status) {
    case 0:
      return AppColors.textSecondary;
    case 2:
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}

// ── Badge kecil serbaguna ───────────────────────────────────────────────────

class ForumBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const ForumBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
