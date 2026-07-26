import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/kalender_konteks_entity.dart';
import 'kalender_visuals.dart';

/// Strip konteks akademik di bawah selector bulan: tahun ajaran aktif,
/// semester aktif, dan hari operasional sekolah.
///
/// Ketiganya opsional — bila endpointnya tidak dapat diakses (permission
/// `tahun-ajaran.view` / `semester.view` / `hari-operasional.view` terpisah dari
/// `kalender-akademik.view`), bagian yang kosong tidak dirender.
class KalenderKonteksHeader extends StatelessWidget {
  final KalenderKonteksEntity konteks;

  const KalenderKonteksHeader({super.key, required this.konteks});

  @override
  Widget build(BuildContext context) {
    if (konteks.isKosong) return const SizedBox.shrink();

    final ta = konteks.tahunAjaranAktif;
    final semester = konteks.semesterAktif;
    final hariSekolah = _ringkasHariOperasional(konteks.weekdayAktif);

    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [
                    if (ta != null)
                      'T.A. ${ta.nama.isEmpty ? ta.kode : ta.nama}',
                    if (semester != null && semester.nama.isNotEmpty)
                      'Semester ${semester.nama}',
                  ].join('  ·  '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (semester?.tanggalMulai != null &&
              semester?.tanggalSelesai != null) ...[
            const SizedBox(height: 3),
            _BarisKecil(
              icon: Icons.date_range_outlined,
              teks: _rentangSemester(semester!),
            ),
          ],
          if (hariSekolah != null) ...[
            const SizedBox(height: 3),
            _BarisKecil(
              icon: Icons.event_available_outlined,
              teks: 'Hari sekolah: $hariSekolah',
            ),
          ],
        ],
      ),
    );
  }

  static String _rentangSemester(SemesterEntity s) {
    final mulai = DateTime.tryParse(s.tanggalMulai ?? '');
    final selesai = DateTime.tryParse(s.tanggalSelesai ?? '');
    if (mulai == null || selesai == null) return '';
    return '${formatTanggalPendek(mulai)} – ${formatTanggalPendek(selesai)}';
  }

  /// "Sen – Jum" bila berurutan, selain itu "Sen, Rab, Jum".
  static String? _ringkasHariOperasional(List<int> weekdays) {
    if (weekdays.isEmpty) return null;
    final berurutan =
        weekdays.length > 2 &&
        weekdays.last - weekdays.first == weekdays.length - 1;
    if (berurutan) {
      return '${labelHariPendek(weekdays.first)} – '
          '${labelHariPendek(weekdays.last)}';
    }
    return weekdays.map(labelHariPendek).join(', ');
  }
}

class _BarisKecil extends StatelessWidget {
  final IconData icon;
  final String teks;

  const _BarisKecil({required this.icon, required this.teks});

  @override
  Widget build(BuildContext context) {
    if (teks.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            teks,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
