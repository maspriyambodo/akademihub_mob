import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/materi_entity.dart';

// ── Format tanggal (manual, tanpa bergantung init locale id_ID) ──────────────

const List<String> _bulanPendek = [
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

String _dua(int v) => v.toString().padLeft(2, '0');

String formatTanggal(DateTime? d) {
  if (d == null) return '-';
  return '${d.day} ${_bulanPendek[d.month]} ${d.year}';
}

String formatTanggalWaktu(DateTime? d) {
  if (d == null) return '-';
  return '${formatTanggal(d)} · ${_dua(d.hour)}:${_dua(d.minute)}';
}

bool _localeTerdaftar = false;

/// Daftarkan pesan locale Indonesia untuk `timeago`. Aman dipanggil
/// berkali-kali dan hanya dipakai oleh fitur materi.
void ensureTimeagoIdLocale() {
  if (_localeTerdaftar) return;
  timeago.setLocaleMessages('id', timeago.IdMessages());
  _localeTerdaftar = true;
}

/// Contoh hasil: "3 hari yang lalu".
String waktuRelatif(DateTime? date) {
  if (date == null) return '-';
  ensureTimeagoIdLocale();
  return timeago.format(date, locale: 'id');
}

/// Durasi detik → "1 jam 5 menit" / "45 detik".
String formatDurasi(int detik) {
  if (detik <= 0) return '0 detik';
  final jam = detik ~/ 3600;
  final menit = (detik % 3600) ~/ 60;
  final sisa = detik % 60;

  final bagian = <String>[];
  if (jam > 0) bagian.add('$jam jam');
  if (menit > 0) bagian.add('$menit menit');
  if (sisa > 0 || bagian.isEmpty) bagian.add('$sisa detik');
  return bagian.join(' ');
}

// ── Visual per tipe materi ───────────────────────────────────────────────────

IconData ikonMateri(MateriTipe tipe) => switch (tipe) {
  MateriTipe.video => Icons.play_circle_outline,
  MateriTipe.dokumen => Icons.description_outlined,
  MateriTipe.teks => Icons.menu_book_outlined,
};

Color warnaMateri(MateriTipe tipe) => switch (tipe) {
  MateriTipe.video => AppColors.error,
  MateriTipe.dokumen => AppColors.primary,
  MateriTipe.teks => AppColors.secondary,
};

// ── Badge ────────────────────────────────────────────────────────────────────

class MateriBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const MateriBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
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

// ── Kartu materi ─────────────────────────────────────────────────────────────

class MateriCard extends StatelessWidget {
  final MateriEntity materi;
  final VoidCallback onTap;

  /// Tampilkan badge status Aktif/Draft (guru & admin).
  final bool tampilkanStatus;

  const MateriCard({
    super.key,
    required this.materi,
    required this.onTap,
    this.tampilkanStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final tipe = materi.tipe;
    final warna = warnaMateri(tipe);
    final ext = materi.ekstensiFile;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.pagePadding(context).left,
        vertical: 5,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: warna.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(ikonMateri(tipe), size: 20, color: warna),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          materi.judul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${materi.mapelLabel} · ${materi.guruLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tampilkanStatus) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: MateriBadge(
                        label:
                            materi.statusLabel ??
                            (materi.isAktif ? 'Aktif' : 'Draft'),
                        color: materi.isAktif
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
              if (materi.deskripsi != null &&
                  materi.deskripsi!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  materi.deskripsi!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Flexible(
                    child: MateriBadge(
                      label: ext == null
                          ? tipe.label
                          : '${tipe.label} · ${ext.toUpperCase()}',
                      color: warna,
                      icon: ikonMateri(tipe),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.schedule,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formatTanggal(materi.createdAtDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header kelompok mata pelajaran ───────────────────────────────────────────

class MateriGroupHeader extends StatelessWidget {
  final String label;
  final int total;

  const MateriGroupHeader({
    super.key,
    required this.label,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$total materi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu section (dipakai halaman detail) ───────────────────────────────────

class MateriSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const MateriSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
