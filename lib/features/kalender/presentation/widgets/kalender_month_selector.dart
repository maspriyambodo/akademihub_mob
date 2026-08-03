import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
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
    final rapat = Responsive.isCompact(context);

    // Di 320dp tiga tombol ikon berukuran penuh menyisakan ruang sangat sempit
    // untuk label bulan, jadi tombol dirapatkan dan label di-scale-down.
    final batasTombol = BoxConstraints(
      minWidth: rapat ? 36 : 44,
      minHeight: rapat ? 36 : 44,
    );

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: rapat ? 2 : 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            padding: EdgeInsets.zero,
            constraints: batasTombol,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${labelBulan(bulan)} $tahun',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Kembali ke bulan ini',
            padding: EdgeInsets.zero,
            constraints: batasTombol,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.today_outlined,
              size: 20,
              color: isBulanIni ? Colors.white38 : Colors.white,
            ),
            onPressed: isBulanIni ? null : onKembaliKeBulanIni,
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            padding: EdgeInsets.zero,
            constraints: batasTombol,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
