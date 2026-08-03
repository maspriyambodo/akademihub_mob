import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/kalender_agenda_item.dart';
import 'kalender_visuals.dart';

/// Chip kecil berwarna untuk kategori/badge.
class KalenderChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool solid;

  const KalenderChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Chip kategori bisa berlabel panjang; dibatasi lebarnya agar
      // meng-ellipsis, bukan meluber keluar kartu.
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: solid ? color : color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(solid ? 255 : 100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: solid ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: solid ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu agenda pada linimasa.
class KalenderAgendaCard extends StatelessWidget {
  final KalenderAgendaItem item;

  /// Menandai kartu sebagai bagian dari blok "Agenda Hari Ini".
  final bool sorotHariIni;

  final VoidCallback? onTap;

  const KalenderAgendaCard({
    super.key,
    required this.item,
    this.sorotHariIni = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = warnaTipe(item.tipe);
    final mulai = item.mulaiDate;
    final selesai = item.selesaiDate;
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final berlangsung = item.sedangBerlangsung(hariIni);
    final waktu = formatRentangWaktu(item.waktuMulai, item.waktuSelesai);
    final statusLabel = labelStatus(item.status);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.pagePadding(context).left,
        vertical: 5,
      ),
      clipBehavior: Clip.antiAlias,
      elevation: sorotHariIni ? 3 : 1.5,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: warna, width: 5)),
            color: sorotHariIni ? warna.withAlpha(12) : null,
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BlokTanggal(
                mulai: mulai,
                selesai: selesai,
                warna: warna,
                jumlahHari: item.jumlahHari,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judul,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        decoration: item.isDibatalkan
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        KalenderChip(
                          label: item.tipe?.nama ?? 'Tanpa Kategori',
                          color: warna,
                          icon: ikonTipe(item.tipe),
                        ),
                        if (item.sumber == KalenderSumber.harian)
                          KalenderChip(
                            label: labelSumber(item.sumber),
                            color: warnaSumber(item.sumber),
                            icon: ikonSumber(item.sumber),
                          ),
                        if (berlangsung)
                          KalenderChip(
                            label: item.isRentang
                                ? 'Sedang berlangsung'
                                : 'Hari ini',
                            color: AppColors.success,
                            icon: Icons.play_circle_outline,
                            solid: true,
                          ),
                        if (statusLabel != null)
                          KalenderChip(
                            label: statusLabel,
                            color: warnaStatus(item.status),
                            icon: item.isDibatalkan
                                ? Icons.cancel_outlined
                                : Icons.check_circle_outline,
                          ),
                        if (item.isPrioritasTinggi && !item.isDibatalkan)
                          const KalenderChip(
                            label: 'Penting',
                            color: AppColors.warning,
                            icon: Icons.priority_high_rounded,
                          ),
                      ],
                    ),
                    if (item.deskripsi != null &&
                        item.deskripsi!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.deskripsi!.trim(),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.catatan != null &&
                        item.catatan!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.sticky_note_2_outlined,
                            size: 13,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.catatan!.trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                fontStyle: FontStyle.italic,
                                color: AppColors.secondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (waktu.isNotEmpty ||
                        (item.lokasi != null &&
                            item.lokasi!.trim().isNotEmpty) ||
                        item.isAllDay) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (item.isAllDay && waktu.isEmpty)
                            const _MetaBaris(
                              icon: Icons.schedule,
                              teks: 'Sepanjang hari',
                            ),
                          if (waktu.isNotEmpty)
                            _MetaBaris(icon: Icons.schedule, teks: waktu),
                          if (item.lokasi != null &&
                              item.lokasi!.trim().isNotEmpty)
                            _MetaBaris(
                              icon: Icons.place_outlined,
                              teks: item.lokasi!.trim(),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaBaris extends StatelessWidget {
  final IconData icon;
  final String teks;

  const _MetaBaris({required this.icon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            teks,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Blok tanggal di sisi kiri kartu. Untuk agenda rentang, menampilkan tanggal
/// awal + jumlah hari.
class _BlokTanggal extends StatelessWidget {
  final DateTime? mulai;
  final DateTime? selesai;
  final Color warna;
  final int jumlahHari;

  const _BlokTanggal({
    required this.mulai,
    required this.selesai,
    required this.warna,
    required this.jumlahHari,
  });

  @override
  Widget build(BuildContext context) {
    final d = mulai;
    final lebar = Responsive.isCompact(context) ? 42.0 : 46.0;

    return SizedBox(
      width: lebar,
      child: Column(
        children: [
          Container(
            width: lebar,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: warna.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: warna.withAlpha(80)),
            ),
            child: Column(
              children: [
                // FittedBox: blok tanggal harus tetap muat walau font sistem
                // diperbesar (kolom ini sempit dan lebarnya pasti).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    d == null ? '--' : labelHariPendek(d.weekday),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: warna,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    d == null ? '-' : '${d.day}',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 19),
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      color: warna,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    d == null ? '' : labelBulanPendek(d.month),
                    maxLines: 1,
                    style: TextStyle(fontSize: 10, height: 1.1, color: warna),
                  ),
                ),
              ],
            ),
          ),
          if (selesai != null && jumlahHari > 1) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$jumlahHari hari',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
