import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/tv_snapshot.dart';

class TvSlideCalendar extends StatelessWidget {
  final List<TvCalendarItem> calendar;

  const TvSlideCalendar({super.key, required this.calendar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.event_note, color: Color(0xFFE9A23B), size: 24),
            SizedBox(width: 10),
            Text(
              'AGENDA & KALENDER AKADEMIK',
              style: TextStyle(
                color: Color(0xFFBFE8DF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
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
                    style: TextStyle(color: Colors.white60, fontSize: 18),
                  ),
                )
              : ListView.separated(
                  itemCount: calendar.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = calendar[index];
                    final dateRange = DateFormat('dd MMM yyyy').format(item.startsAt.toLocal());

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102A43),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF243B53), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF243B53),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateRange,
                              style: const TextStyle(
                                color: Color(0xFFE9A23B),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (item.allDay)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF087F75).withAlpha(60),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Sepanjang Hari',
                                style: TextStyle(color: Color(0xFFBFE8DF), fontSize: 11),
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
