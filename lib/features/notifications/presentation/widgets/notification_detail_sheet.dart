import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/notification_entity.dart';
import 'notification_visuals.dart';

/// Bottom sheet detail isi notifikasi.
class NotificationDetailSheet extends StatelessWidget {
  final NotificationEntity item;

  const NotificationDetailSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, NotificationEntity item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificationDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visual = visualForType(item.type);
    final payload = _payloadEntries();
    final pad = Responsive.pagePadding(context);
    final bawahKeyboard = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Tinggi aman: memperhitungkan keyboard & area sistem, tidak
          // sekadar 80% tinggi layar.
          maxHeight: Responsive.tinggiSheet(context, rasio: 0.8),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            pad.left + 4,
            12,
            pad.right + 4,
            20 + bawahKeyboard,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ──────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Header: ikon + tipe + urgensi ───────────────────────────
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: visual.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(visual.icon, color: visual.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visual.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: visual.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${waktuRelatif(item.createdAt)} • ${waktuLengkap(item.createdAt)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.urgency.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorForUrgency(item.urgency).withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          labelForUrgency(item.urgency),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorForUrgency(item.urgency),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              // ── Judul & pesan ───────────────────────────────────────────
              Text(
                item.judul.isEmpty ? visual.label : item.judul,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 17),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.pesan.isEmpty ? '-' : item.pesan,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),

              // ── Payload tambahan (kolom jsonb `data`) ───────────────────
              if (payload.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Detail',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in payload)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: Responsive.isCompact(context) ? 96 : 120,
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ubah payload `data` jadi pasangan label-nilai yang enak dibaca.
  /// Struktur payload berbeda-beda per tipe (`nama_siswa`, `mapel_nama`,
  /// `risk_score`, dst.), jadi key mentah diformat generik.
  List<MapEntry<String, String>> _payloadEntries() {
    final data = item.data;
    if (data == null || data.isEmpty) return const [];

    final entries = <MapEntry<String, String>>[];
    data.forEach((key, value) {
      if (value == null) return;
      if (value is Map || value is List) return; // lewati struktur bersarang
      final text = value.toString().trim();
      if (text.isEmpty) return;
      entries.add(MapEntry(_humanizeKey(key), text));
    });
    return entries;
  }

  String _humanizeKey(String key) {
    final words = key.split('_').where((w) => w.isNotEmpty);
    return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
