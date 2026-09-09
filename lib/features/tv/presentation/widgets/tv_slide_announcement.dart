import 'package:flutter/material.dart';
import '../../domain/entities/tv_snapshot.dart';

class TvSlideAnnouncement extends StatelessWidget {
  final TvAnnouncementItem announcement;

  const TvSlideAnnouncement({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final isUrgent =
        announcement.priority.toLowerCase() == 'urgent' ||
        announcement.priority.toLowerCase() == 'high';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? const Color(0xFFB43C46) : const Color(0xFF243B53),
          width: 2,
        ),
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? const Color(0xFFB43C46)
                            : const Color(0xFF087F75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isUrgent ? 'PENGUMUMAN PENTING' : 'PENGUMUMAN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  announcement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      announcement.body,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (announcement.imageUrl != null &&
              announcement.imageUrl!.isNotEmpty) ...[
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  announcement.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
