import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Kode permission backend modul BK (lihat `RbacSeeder` + `routes/api.php`).
const String bkPermKasusView = 'bk-kasus.view';
const String bkPermKasusCreate = 'bk-kasus.create';
const String bkPermSesiView = 'bk-sesi.view';
const String bkPermSesiManage = 'bk-sesi.manage';
const String bkPermHasilView = 'bk-hasil.view';
const String bkPermHasilManage = 'bk-hasil.manage';
const String bkPermTindakanView = 'bk-tindakan.view';
const String bkPermTindakanManage = 'bk-tindakan.manage';
const String bkPermJenisView = 'bk-jenis.view';
const String bkPermSiswaView = 'siswa.view';

/// `sys_roles.code` bisa UPPERCASE (`SISWA`, `GURU`, `WALI_SISWA`, `GURU_BK`)
/// sementara `UserEntity.role` bisa lowercase. Normalisasi ke lowercase dan
/// cek `wali` SEBELUM `siswa` (karena `WALI_SISWA` memuat substring `siswa`).
/// `guru_bk`/`wali_kelas` ikut ternormalisasi menjadi `guru`.
String bkNormalisasiRole(String? role) {
  final r = (role ?? '').trim().toLowerCase();
  if (r.isEmpty) return '';
  if (r.contains('wali_kelas')) return 'guru';
  if (r.contains('wali')) return 'wali';
  if (r.contains('guru')) return 'guru';
  if (r.contains('siswa')) return 'siswa';
  if (r.contains('admin')) return 'admin';
  return r;
}

const List<String> _bkNamaBulan = [
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

/// Format `yyyy-MM-dd` / ISO 8601 → `12 Mei 2026` tanpa bergantung pada
/// inisialisasi locale `intl`.
String bkFormatTanggal(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  final d = DateTime.tryParse(raw);
  if (d == null) return raw;
  return '${d.day} ${_bkNamaBulan[d.month - 1]} ${d.year}';
}

String bkFormatTanggalDate(DateTime? d) {
  if (d == null) return '-';
  return '${d.day} ${_bkNamaBulan[d.month - 1]} ${d.year}';
}

/// Warna untuk label status kasus (ref `status_bk`:
/// 1 dibuka, 2 proses, 3 selesai, 4 dirujuk).
Color bkWarnaStatus(String label) {
  final s = label.toLowerCase();
  if (s.contains('selesai')) return AppColors.success;
  if (s.contains('proses')) return AppColors.warning;
  if (s.contains('dirujuk')) return AppColors.error;
  if (s.contains('dibuka')) return AppColors.info;
  return AppColors.textSecondary;
}

IconData bkIkonStatus(String label) {
  final s = label.toLowerCase();
  if (s.contains('selesai')) return Icons.check_circle_outline;
  if (s.contains('proses')) return Icons.autorenew;
  if (s.contains('dirujuk')) return Icons.outbound_outlined;
  if (s.contains('dibuka')) return Icons.folder_open_outlined;
  return Icons.help_outline;
}

IconData bkIkonMetode(String label) {
  final s = label.toLowerCase();
  if (s.contains('online')) return Icons.videocam_outlined;
  if (s.contains('telepon')) return Icons.call_outlined;
  return Icons.people_outline; // tatap muka
}

/// Badge kecil berisi status kasus.
class BkStatusBadge extends StatelessWidget {
  final String label;

  const BkStatusBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final warna = bkWarnaStatus(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warna.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(bkIkonStatus(label), size: 12, color: warna),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
