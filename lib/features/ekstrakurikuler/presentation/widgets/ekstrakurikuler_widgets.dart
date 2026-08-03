import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/ekstrakurikuler_entity.dart';
import '../../domain/entities/pendaftaran_ekskul_entity.dart';

/// Membatasi lebar konten daftar di tablet agar teks tidak melebar
/// tak terbaca. Dipakai di level halaman, bukan per kartu.
class BatasLebarKonten extends StatelessWidget {
  final Widget child;

  const BatasLebarKonten({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isExpanded(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.lebarKontenMaks(context),
        ),
        child: child,
      ),
    );
  }
}

// ── Format tanggal (manual, tanpa initializeDateFormatting) ──────────────────

const List<String> _namaBulan = <String>[
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

/// Mengubah `yyyy-MM-dd` menjadi `d Mmm yyyy` (mis. `5 Agu 2025`).
String formatTanggalIndo(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final tanggal = DateTime.tryParse(raw);
  if (tanggal == null) return raw;
  return '${tanggal.day} ${_namaBulan[tanggal.month - 1]} ${tanggal.year}';
}

/// Warna aksen per huruf awal nama ekskul, supaya kartu tidak monoton.
Color warnaEkskul(String nama) {
  const palet = <Color>[
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.info,
    AppColors.siswaColor,
    AppColors.guruColor,
    AppColors.waliColor,
  ];
  if (nama.isEmpty) return AppColors.primary;
  return palet[nama.codeUnitAt(0) % palet.length];
}

// ── Badge status ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Batas lebar agar label panjang meng-ellipsis alih-alih meluber.
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.8),
      ),
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
    );
  }
}

// ── Baris info ikon + teks ───────────────────────────────────────────────────

class InfoBaris extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const InfoBaris({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu ekstrakurikuler (tab Semua & tab guru) ─────────────────────────────

class EkstrakurikulerCard extends StatelessWidget {
  final EkstrakurikulerEntity ekskul;

  /// Jumlah peserta aktif bila sudah diketahui (opsional).
  final int? jumlahPeserta;

  final bool sudahTerdaftar;
  final VoidCallback? onTap;
  final VoidCallback? onDaftar;

  const EkstrakurikulerCard({
    super.key,
    required this.ekskul,
    this.jumlahPeserta,
    this.sudahTerdaftar = false,
    this.onTap,
    this.onDaftar,
  });

  @override
  Widget build(BuildContext context) {
    final warna = warnaEkskul(ekskul.nama);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: warna.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.sports_soccer, color: warna, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ekskul.nama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (ekskul.kode != null && ekskul.kode!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              ekskul.kode!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: ekskul.statusLabel,
                    color: ekskul.isAktif ? AppColors.success : AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InfoBaris(
                icon: Icons.person_outline,
                text: ekskul.hasPembina
                    ? 'Pembina: ${ekskul.pembinaNama}'
                    : 'Pembina belum ditentukan',
              ),
              InfoBaris(icon: Icons.event_outlined, text: ekskul.jadwalLabel),
              if (ekskul.lokasi != null && ekskul.lokasi!.isNotEmpty)
                InfoBaris(icon: Icons.place_outlined, text: ekskul.lokasi!),
              if (jumlahPeserta != null)
                InfoBaris(
                  icon: Icons.groups_outlined,
                  text: '$jumlahPeserta peserta aktif',
                ),
              if (sudahTerdaftar || onDaftar != null) ...[
                const SizedBox(height: 10),
                // Wrap: badge/tombol turun baris di layar sempit.
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (sudahTerdaftar)
                      const StatusBadge(
                        label: 'Sudah terdaftar',
                        color: AppColors.info,
                      )
                    else if (onDaftar != null)
                      ElevatedButton.icon(
                        onPressed: onDaftar,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Daftar'),
                        style: ElevatedButton.styleFrom(
                          // minimumSize (bukan tinggi mati) supaya tombol ikut
                          // tumbuh saat font sistem diperbesar.
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kartu keanggotaan (tab Ekskul Saya) ──────────────────────────────────────

class KeanggotaanCard extends StatelessWidget {
  final PendaftaranEkskulEntity pendaftaran;

  /// Nama siswa ditampilkan untuk role wali/admin.
  final bool tampilkanSiswa;

  final VoidCallback? onTap;
  final VoidCallback? onKeluar;

  const KeanggotaanCard({
    super.key,
    required this.pendaftaran,
    this.tampilkanSiswa = false,
    this.onTap,
    this.onKeluar,
  });

  @override
  Widget build(BuildContext context) {
    final aktif = pendaftaran.isAktif;
    final warna = warnaEkskul(pendaftaran.namaTampil);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: warna.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      aktif ? Icons.verified_outlined : Icons.history,
                      color: warna,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pendaftaran.namaTampil,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: pendaftaran.statusLabel,
                    color: aktif ? AppColors.success : AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (tampilkanSiswa && pendaftaran.siswaNama != null)
                InfoBaris(
                  icon: Icons.badge_outlined,
                  text: pendaftaran.siswaNis != null
                      ? '${pendaftaran.siswaNama} (${pendaftaran.siswaNis})'
                      : pendaftaran.siswaNama!,
                ),
              InfoBaris(
                icon: Icons.calendar_today_outlined,
                text:
                    'Bergabung ${formatTanggalIndo(pendaftaran.tanggalDaftar)}',
              ),
              if (pendaftaran.ekstrakurikulerDeskripsi != null &&
                  pendaftaran.ekstrakurikulerDeskripsi!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    pendaftaran.ekstrakurikulerDeskripsi!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (aktif && onKeluar != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onKeluar,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Keluar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kartu statistik peserta ──────────────────────────────────────────────────

class StatistikTile extends StatelessWidget {
  final String label;
  final int nilai;
  final Color color;

  const StatistikTile({
    super.key,
    required this.label,
    required this.nilai,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            // Angka statistik bisa 3–4 digit di kolom sempit → scaleDown.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$nilai',
                maxLines: 1,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner catatan / keterbatasan data ───────────────────────────────────────

class CatatanBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const CatatanBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = AppColors.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 0.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
