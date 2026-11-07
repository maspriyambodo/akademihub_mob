import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../theme/tv_theme.dart';

class TvSlideCalendar extends StatelessWidget {
  final List<TvCalendarItem> calendar;
  final int utcOffsetSeconds;

  const TvSlideCalendar({super.key, required this.calendar, this.utcOffsetSeconds = 25200});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_note, color: TvColors.gold, size: 22),
            const SizedBox(width: 10),
            const Text(
              'AGENDA & KALENDER AKADEMIK',
              style: TextStyle(
                color: TvColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: TvColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AGENDA RESMI',
                style: TextStyle(
                  color: TvColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: calendar.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada agenda akademik terdekat.',
                    style: TextStyle(color: TvColors.textMuted, fontSize: 18),
                  ),
                )
              : ListView.separated(
                  itemCount: calendar.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = calendar[index];
                    final dateRange = DateFormat(
                      'dd MMM yyyy',
                    ).format(item.startsAt.toUtc().add(Duration(seconds: utcOffsetSeconds)));

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: TvColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: TvColors.border,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: TvColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: TvColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  color: TvColors.gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateRange,
                                  style: const TextStyle(
                                    color: TvColors.gold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: TvColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.allDay)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: TvColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: TvColors.primary.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'Sepanjang Hari',
                                style: TextStyle(
                                  color: TvColors.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
