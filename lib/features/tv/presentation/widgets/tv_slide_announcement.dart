import 'package:flutter/material.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../theme/tv_theme.dart';

class TvSlideAnnouncement extends StatelessWidget {
  final TvAnnouncementItem announcement;

  const TvSlideAnnouncement({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final isUrgent =
        announcement.priority.toLowerCase() == 'urgent' ||
        announcement.priority.toLowerCase() == 'high';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: TvColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent ? TvColors.rose : TvColors.border,
          width: isUrgent ? 2 : 1.2,
        ),
        boxShadow: [
          if (isUrgent)
            BoxShadow(
              color: TvColors.rose.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isUrgent ? TvColors.rose : TvColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUrgent ? Icons.warning_amber_rounded : Icons.campaign,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isUrgent ? 'PENGUMUMAN PENTING' : 'PENGUMUMAN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  announcement.title,
                  style: const TextStyle(
                    color: TvColors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      announcement.body,
                      style: const TextStyle(
                        color: TvColors.textMuted,
                        fontSize: 20,
                        height: 1.65,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (announcement.imageUrl != null &&
              announcement.imageUrl!.isNotEmpty) ...[
            const SizedBox(width: 28),
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: TvColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.network(
                    announcement.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
