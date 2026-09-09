import 'package:flutter/material.dart';
import '../../domain/entities/tv_snapshot.dart';

class TvStatusBadge extends StatelessWidget {
  final TvDeviceSummary device;
  final bool isOffline;
  final TvAttendanceSummary? attendance;

  const TvStatusBadge({
    super.key,
    required this.device,
    required this.isOffline,
    this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Mode and Connection status
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF243B53),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                device.mode.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFBFE8DF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOffline
                    ? const Color(0xFFB43C46).withAlpha(40)
                    : const Color(0xFF087F75).withAlpha(40),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOffline ? const Color(0xFFB43C46) : const Color(0xFF087F75),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOffline ? const Color(0xFFB43C46) : const Color(0xFF087F75),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOffline ? 'OFFLINE (CACHE)' : 'TERHUBUNG',
                    style: TextStyle(
                      color: isOffline ? const Color(0xFFFFA39E) : const Color(0xFF87E8DE),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Attendance stats (if available)
        if (attendance != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF102A43),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF243B53)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_outlined, color: Color(0xFFE9A23B), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Hadir: ${attendance!.present}/${attendance!.total}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (attendance!.late > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• Terlambat: ${attendance!.late}',
                    style: const TextStyle(
                      color: Color(0xFFE9A23B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
