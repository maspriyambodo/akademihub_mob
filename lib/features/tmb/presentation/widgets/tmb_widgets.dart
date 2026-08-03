import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/tmb_hasil_entity.dart';
import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/entities/tmb_tes_entity.dart';

// ── Format tanggal manual (tanpa bergantung inisialisasi locale intl) ────────

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

String formatTmbTanggal(DateTime? d) {
  if (d == null) return '-';
  return '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';
}

String formatTmbTanggalJam(DateTime? d) {
  if (d == null) return '-';
  final jam = d.hour.toString().padLeft(2, '0');
  final menit = d.minute.toString().padLeft(2, '0');
  return '${formatTmbTanggal(d)} $jam:$menit';
}

// ── Chip status ──────────────────────────────────────────────────────────────

class TmbStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const TmbStatusChip({super.key, required this.label, required this.color});

  factory TmbStatusChip.keikutsertaan(TmbPesertaEntity? peserta) {
    if (peserta == null) {
      return const TmbStatusChip(
        label: 'Belum Terdaftar',
        color: AppColors.textSecondary,
      );
    }
    switch (peserta.status) {
      case TmbPesertaEntity.statusBerjalan:
        return const TmbStatusChip(
          label: 'Sedang Berjalan',
          color: AppColors.warning,
        );
      case TmbPesertaEntity.statusSelesai:
        return const TmbStatusChip(label: 'Selesai', color: AppColors.success);
      case TmbPesertaEntity.statusTimeout:
        return const TmbStatusChip(
          label: 'Waktu Habis',
          color: AppColors.error,
        );
      default:
        return const TmbStatusChip(label: 'Terdaftar', color: AppColors.info);
    }
  }

  factory TmbStatusChip.tes(TmbTesEntity tes) {
    switch (tes.status) {
      case TmbTesEntity.statusDibuka:
        return const TmbStatusChip(label: 'Dibuka', color: AppColors.success);
      case TmbTesEntity.statusDitutup:
        return const TmbStatusChip(label: 'Ditutup', color: AppColors.error);
      default:
        return const TmbStatusChip(
          label: 'Draf',
          color: AppColors.textSecondary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
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

// ── Banner catatan non-fatal ─────────────────────────────────────────────────

class TmbCatatanBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const TmbCatatanBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = AppColors.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar skor per aspek (widget Flutter murni, tanpa paket chart) ─────────────

class TmbAspekBar extends StatelessWidget {
  final TmbHasilEntity hasil;

  /// Skor total tertinggi antar aspek — dipakai sebagai skala bila
  /// `skor_persen` tidak tersedia.
  final int skorTotalTertinggi;

  const TmbAspekBar({
    super.key,
    required this.hasil,
    required this.skorTotalTertinggi,
  });

  double get _fraksi {
    final persen = hasil.skorPersen;
    if (persen != null) return (persen / 100).clamp(0.0, 1.0);
    if (skorTotalTertinggi <= 0) return 0;
    return (hasil.skorTotal / skorTotalTertinggi).clamp(0.0, 1.0);
  }

  Color get _warna {
    final kategori = (hasil.kategoriTampil ?? '').toLowerCase();
    if (kategori.contains('dominan') || kategori.contains('tinggi')) {
      return AppColors.success;
    }
    if (kategori.contains('cukup') || kategori.contains('sedang')) {
      return AppColors.info;
    }
    if (kategori.contains('rendah')) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final persen = hasil.skorPersen;
    final nilaiLabel = persen != null ? '$persen%' : '${hasil.skorTotal}';
    final kategori = hasil.kategoriTampil;
    final gap = Responsive.gap(context, base: 8);
    // Lebar maksimum chip kategori dibatasi agar Row tidak pernah overflow
    // meski label aspek dan kategori sama-sama panjang di layar sempit.
    final lebarMaksChip = Responsive.isCompact(context) ? 72.0 : 96.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasil.aspekKode != null && hasil.aspekKode!.isNotEmpty) ...[
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _warna.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    hasil.aspekKode!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _warna,
                    ),
                  ),
                ),
                SizedBox(width: gap),
              ],
              Expanded(
                child: Text(
                  hasil.namaTampil,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (kategori != null) ...[
                SizedBox(width: gap * 0.75),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: lebarMaksChip),
                  child: TmbStatusChip(label: kategori, color: _warna),
                ),
              ],
              SizedBox(width: gap),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 32, maxWidth: 56),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    nilaiLabel,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _warna,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: AppColors.divider.withAlpha(120)),
                  FractionallySizedBox(
                    widthFactor: _fraksi,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _warna,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Baris info kecil berikon ─────────────────────────────────────────────────

class TmbInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const TmbInfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
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
