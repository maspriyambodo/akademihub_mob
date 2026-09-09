import 'package:flutter/material.dart';
import '../../domain/entities/tv_snapshot.dart';

class TvSlideSchedule extends StatelessWidget {
  final List<TvScheduleItem> schedule;

  const TvSlideSchedule({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFFE9A23B), size: 24),
            SizedBox(width: 10),
            Text(
              'JADWAL PELAJARAN HARI INI',
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
          child: schedule.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada jadwal pelajaran hari ini.',
                    style: TextStyle(color: Colors.white60, fontSize: 18),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: schedule.length,
                  itemBuilder: (context, index) {
                    final item = schedule[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102A43),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF243B53), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF087F75),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.startsAt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const Text('-', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(item.endsAt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.subject,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(item.teacher, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text('${item.className}${item.room != null ? ' • ${item.room}' : ''}', style: const TextStyle(color: Color(0xFFE9A23B), fontSize: 12)),
                              ],
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
