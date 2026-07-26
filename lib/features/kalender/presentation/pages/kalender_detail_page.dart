import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/kalender_agenda_item.dart';
import '../widgets/kalender_agenda_card.dart';
import '../widgets/kalender_visuals.dart';

/// Halaman detail satu agenda. Dibuka lewat `Navigator.push` dari
/// [KalenderPage] — modul kalender bersifat baca-saja di mobile, jadi tidak ada
/// aksi ubah/hapus di sini.
class KalenderDetailPage extends StatelessWidget {
  final KalenderAgendaItem item;

  const KalenderDetailPage({super.key, required this.item});

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
    final prioritasLabel = labelPrioritas(item.prioritas);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Agenda'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Kepala ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: warna.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: warna.withAlpha(90)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: warna.withAlpha(45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(ikonTipe(item.tipe), color: warna, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.judul,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          decoration: item.isDibatalkan
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    KalenderChip(
                      label: item.tipe?.nama ?? 'Tanpa Kategori',
                      color: warna,
                      icon: ikonTipe(item.tipe),
                    ),
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
                    if (prioritasLabel != null)
                      KalenderChip(
                        label: prioritasLabel,
                        color: item.isPrioritasTinggi
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        icon: Icons.flag_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Informasi ───────────────────────────────────────────────────
          _Seksi(
            judul: 'Informasi',
            anak: [
              _BarisInfo(
                icon: Icons.event_outlined,
                label: 'Tanggal',
                nilai: mulai == null
                    ? '-'
                    : formatRentangTanggal(mulai, selesai),
              ),
              if (mulai != null)
                _BarisInfo(
                  icon: Icons.timelapse_outlined,
                  label: 'Mulai',
                  nilai:
                      '${formatTanggalPanjang(mulai)}  ·  '
                      '${labelRelatif(mulai, hariIni)}',
                ),
              if (item.isRentang)
                _BarisInfo(
                  icon: Icons.date_range_outlined,
                  label: 'Durasi',
                  nilai: '${item.jumlahHari} hari',
                ),
              _BarisInfo(
                icon: Icons.schedule,
                label: 'Waktu',
                nilai: waktu.isNotEmpty
                    ? waktu
                    : (item.isAllDay ? 'Sepanjang hari' : '-'),
              ),
              if (item.lokasi != null && item.lokasi!.trim().isNotEmpty)
                _BarisInfo(
                  icon: Icons.place_outlined,
                  label: 'Lokasi',
                  nilai: item.lokasi!.trim(),
                ),
            ],
          ),

          if (item.deskripsi != null && item.deskripsi!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Seksi(
              judul: 'Deskripsi',
              anak: [
                Text(
                  item.deskripsi!.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          if (item.catatan != null && item.catatan!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Seksi(
              judul: 'Catatan Harian',
              anak: [
                Text(
                  item.catatan!.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          if (item.tipe?.keterangan != null &&
              item.tipe!.keterangan!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Seksi(
              judul: 'Tentang Kategori',
              anak: [
                Text(
                  item.tipe!.keterangan!.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Seksi extends StatelessWidget {
  final String judul;
  final List<Widget> anak;

  const _Seksi({required this.judul, required this.anak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...anak,
        ],
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String nilai;

  const _BarisInfo({
    required this.icon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
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
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
