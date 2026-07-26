import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'kalender_visuals.dart';

/// Selector bulan/tahun untuk halaman kalender.
///
/// Ditulis khusus untuk fitur ini (tidak mengimpor lintas fitur), dengan dua
/// perbedaan dari `_MonthSelector` di absensi:
/// 1. Tombol "next" TIDAK dibatasi bulan berjalan — kalender akademik justru
///    dipakai untuk melihat agenda yang akan datang.
/// 2. Ada tombol pintas kembali ke bulan berjalan.
class KalenderMonthSelector extends StatelessWidget {
  final int bulan;
  final int tahun;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onKembaliKeBulanIni;

  const KalenderMonthSelector({
    super.key,
    required this.bulan,
    required this.tahun,
    required this.onPrev,
    required this.onNext,
    required this.onKembaliKeBulanIni,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isBulanIni = bulan == now.month && tahun == now.year;

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                '${labelBulan(bulan)} $tahun',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Kembali ke bulan ini',
            icon: Icon(
              Icons.today_outlined,
              size: 20,
              color: isBulanIni ? Colors.white38 : Colors.white,
            ),
            onPressed: isBulanIni ? null : onKembaliKeBulanIni,
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
