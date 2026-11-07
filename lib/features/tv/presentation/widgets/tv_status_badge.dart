import 'package:flutter/material.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../theme/tv_theme.dart';

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
    final pct = attendance != null && attendance!.total > 0
        ? ((attendance!.present / attendance!.total) * 100).round()
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Mode and Connection status
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TvColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TvColors.border),
              ),
              child: Text(
                device.mode.toUpperCase(),
                style: const TextStyle(
                  color: TvColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOffline ? TvColors.roseBg : TvColors.emeraldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOffline
                      ? TvColors.rose.withValues(alpha: 0.6)
                      : TvColors.emerald.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOffline ? TvColors.rose : TvColors.emerald,
                      boxShadow: [
                        BoxShadow(
                          color: (isOffline ? TvColors.rose : TvColors.emerald)
                              .withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOffline ? 'OFFLINE (CACHE)' : 'TERHUBUNG',
                    style: TextStyle(
                      color: isOffline
                          ? const Color(0xFFF87171)
                          : const Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: TvColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TvColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  color: TvColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hadir: ${attendance!.present}/${attendance!.total}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pct != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: TvColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$pct%',
                      style: const TextStyle(
                        color: TvColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (attendance!.late > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• Terlambat: ${attendance!.late}',
                    style: const TextStyle(
                      color: TvColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
