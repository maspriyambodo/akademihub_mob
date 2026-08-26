import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/tugas_item_entity.dart';
import '../../domain/entities/tugas_siswa_entity.dart';

// ── Format tanggal (manual, tanpa bergantung pada init locale id_ID) ─────────

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

/// Label sisa waktu menuju deadline, mis. "3 hari lagi" / "Terlambat 2 hari".
String sisaWaktuLabel(DateTime? deadline) {
  if (deadline == null) return 'Tanpa tenggat';
  final selisih = deadline.difference(DateTime.now());
  if (selisih.isNegative) {
    final lewat = selisih.abs();
    if (lewat.inDays >= 1) return 'Lewat ${lewat.inDays} hari';
    if (lewat.inHours >= 1) return 'Lewat ${lewat.inHours} jam';
    return 'Baru saja lewat';
  }
  if (selisih.inDays >= 1) return '${selisih.inDays} hari lagi';
  if (selisih.inHours >= 1) return '${selisih.inHours} jam lagi';
  return '${selisih.inMinutes} menit lagi';
}

// ── Warna status ─────────────────────────────────────────────────────────────

Color statusPengumpulanColor(StatusPengumpulan status) => switch (status) {
  StatusPengumpulan.belum => AppColors.warning,
  StatusPengumpulan.dikumpulkan => AppColors.info,
  StatusPengumpulan.dinilai => AppColors.success,
};

// ── Badge status ─────────────────────────────────────────────────────────────

class TugasBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  /// Batas lebar badge agar label panjang tidak mendorong isi `Row` lain.
  final double maxWidth;

  const TugasBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.maxWidth = 130,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
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

// ── Kartu tugas ──────────────────────────────────────────────────────────────

class TugasCard extends StatelessWidget {
  final TugasItemEntity item;
  final VoidCallback onTap;

  /// Tampilkan badge status pengumpulan (siswa/wali). Guru/admin: false.
  final bool showStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TugasCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showStatus = true,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tugas = item.tugas;
    final deadline = tugas.tenggatWaktuDate;
    final status = item.statusPengumpulan;
    final statusColor = statusPengumpulanColor(status);

    final bool sorotDeadline =
        !item.sudahDikumpulkan &&
        (tugas.isLewatDeadline || tugas.isMendekatiDeadline);
    final Color deadlineColor = tugas.isLewatDeadline
        ? AppColors.error
        : (tugas.isMendekatiDeadline
              ? AppColors.warning
              : AppColors.textSecondary);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.pagePadding(context).left,
        vertical: 5,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(Responsive.isCompact(context) ? 10 : 14),
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
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 20,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tugas.judul,
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
                          [
                            tugas.mapelLabel,
                            if (tugas.kelasNama != null) tugas.kelasNama!,
                          ].join(' · '),
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
                  if (showStatus) ...[
                    const SizedBox(width: 6),
                    TugasBadge(
                      label: status.label,
                      color: statusColor,
                      maxWidth: 110,
                    ),
                  ],
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      tooltip: 'Aksi tugas',
                      onSelected: (action) => action == 'edit'
                          ? onEdit?.call()
                          : onDelete?.call(),
                      itemBuilder: (_) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Ubah'),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    sorotDeadline
                        ? Icons.warning_amber_rounded
                        : Icons.schedule,
                    size: 14,
                    color: deadlineColor,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      deadline == null
                          ? 'Tanpa tenggat'
                          : '${formatTanggalWaktu(deadline)}  (${sisaWaktuLabel(deadline)})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: deadlineColor,
                        fontWeight: sorotDeadline
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (item.pengumpulan?.sudahDinilai == true) ...[
                    const SizedBox(width: 6),
                    TugasBadge(
                      label: 'Nilai ${item.pengumpulan!.nilaiLabel}',
                      color: AppColors.success,
                      icon: Icons.star_rounded,
                      maxWidth: 110,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kartu pengumpulan (view guru) ────────────────────────────────────────────

class PengumpulanCard extends StatelessWidget {
  final TugasSiswaEntity item;
  final VoidCallback onNilai;

  const PengumpulanCard({super.key, required this.item, required this.onNilai});

  @override
  Widget build(BuildContext context) {
    final dinilai = item.sudahDinilai;
    final statusColor = dinilai
        ? AppColors.success
        : (item.isTerlambat ? AppColors.error : AppColors.info);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.pagePadding(context).left,
        vertical: 5,
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.isCompact(context) ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor.withAlpha(30),
                  child: Icon(
                    Icons.person_outline,
                    size: 18,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.siswaNama ?? 'Siswa #${item.siswaId ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (item.siswaNis != null)
                        Text(
                          'NIS ${item.siswaNis}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                TugasBadge(
                  label: item.statusLabel ?? (dinilai ? 'Dinilai' : 'Belum'),
                  color: statusColor,
                  maxWidth: 110,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.upload_file_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.waktuKumpulDate == null
                        ? 'Belum dikumpulkan'
                        : 'Dikumpulkan ${formatTanggalWaktu(item.waktuKumpulDate)}',
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
            if (item.jawaban != null && item.jawaban!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.jawaban!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            if (item.fileJawaban != null && item.fileJawaban!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.fileJawaban!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Badge + tombol: pakai Wrap agar tombol turun baris di layar
            // sempit alih-alih meluber ke samping.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (dinilai)
                  TugasBadge(
                    label: 'Nilai ${item.nilaiLabel}',
                    color: AppColors.success,
                    icon: Icons.star_rounded,
                  )
                else
                  const TugasBadge(
                    label: 'Belum dinilai',
                    color: AppColors.warning,
                  ),
                TextButton.icon(
                  onPressed: onNilai,
                  icon: const Icon(Icons.grading, size: 18),
                  label: Text(
                    dinilai ? 'Ubah Nilai' : 'Beri Nilai',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (item.catatanGuru != null && item.catatanGuru!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Catatan: ${item.catatanGuru}',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
