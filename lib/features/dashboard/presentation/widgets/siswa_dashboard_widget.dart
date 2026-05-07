import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'dashboard_quick_actions.dart';

class SiswaDashboardWidget extends StatelessWidget {
  final DashboardEntity data;

  const SiswaDashboardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profile = data.profile ?? {};
    final attendanceSummary = data.attendanceSummary ?? [];
    final unpaidSpp = data.unpaidSpp ?? [];
    final recentGrades = data.recentGrades ?? [];
    final upcomingTasks = data.upcomingTasks ?? [];

    // Build attendance counts
    int hadirCount = 0, sakitCount = 0, izinCount = 0, alphaCount = 0;
    for (final item in attendanceSummary) {
      final label = (item['status_label'] ?? item['status'] ?? '')
          .toString()
          .toLowerCase();
      final total = (item['total'] as num?)?.toInt() ?? 0;
      if (label.contains('hadir')) {
        hadirCount += total;
      }
      if (label.contains('sakit')) {
        sakitCount += total;
      }
      if (label.contains('izin')) {
        izinCount += total;
      }
      if (label.contains('alpha') || label.contains('alpa')) {
        alphaCount += total;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Selamat Datang, ${profile['nama'] ?? 'Siswa'}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'NIS: ${profile['nis'] ?? '-'}  ·  Kelas: ${profile['kelas'] ?? '-'}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Attendance summary stats
        Text(
          'Ringkasan Kehadiran',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _AttendanceBadge(
              label: 'Hadir',
              value: hadirCount,
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            _AttendanceBadge(
              label: 'Sakit',
              value: sakitCount,
              icon: Icons.local_hospital,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            _AttendanceBadge(
              label: 'Izin',
              value: izinCount,
              icon: Icons.info,
              color: AppColors.info,
            ),
            const SizedBox(width: 8),
            _AttendanceBadge(
              label: 'Alpha',
              value: alphaCount,
              icon: Icons.cancel,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Unpaid SPP
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tunggakan SPP',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (unpaidSpp.isEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Semua SPP lunas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  )
                else
                  ...unpaidSpp.map((spp) => _SppRow(spp: spp)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Recent Grades
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nilai Terbaru',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (recentGrades.isEmpty)
                  Text(
                    'Belum ada nilai.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  ...recentGrades.map((g) => _GradeRow(grade: g)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Upcoming Tasks
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tugas Mendatang',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (upcomingTasks.isEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tidak ada tugas mendatang',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  )
                else
                  ...upcomingTasks.map((t) => _TaskRow(task: t)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Actions
        const DashboardQuickActions(role: 'siswa'),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SppRow extends StatelessWidget {
  final Map<String, dynamic> spp;
  const _SppRow({required this.spp});

  @override
  Widget build(BuildContext context) {
    final amount = (spp['jumlah_bayar'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${spp['bulan_nama'] ?? ''} ${spp['tahun'] ?? ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            'Rp ${_formatCurrency(amount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int val) {
    final s = val.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _GradeRow extends StatelessWidget {
  final Map<String, dynamic> grade;
  const _GradeRow({required this.grade});

  @override
  Widget build(BuildContext context) {
    final ujian = grade['ujian'] as Map<String, dynamic>?;
    final mapel = ujian?['mapel'] as Map<String, dynamic>?;
    final nilai = (grade['nilai'] as num?)?.toDouble() ?? 0;
    final Color gradeColor = nilai >= 80
        ? AppColors.success
        : nilai >= 60
        ? AppColors.warning
        : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.description, color: AppColors.info, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mapel?['nama'] ?? 'Ujian',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (ujian?['nama'] != null)
                  Text(
                    ujian!['nama'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            nilai.toStringAsFixed(nilai % 1 == 0 ? 0 : 1),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: gradeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Map<String, dynamic> task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.purple.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.schedule, color: Colors.purple, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['judul'] ?? task['nama'] ?? 'Tugas',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (task['deadline'] != null || task['batas_waktu'] != null)
                  Text(
                    'Deadline: ${task['deadline'] ?? task['batas_waktu']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _AttendanceBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
