import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../theme/tv_theme.dart';
import 'tv_focusable.dart';

class TvClockHeader extends StatefulWidget {
  final TvSchoolSummary school;
  final VoidCallback onOpenSettings;

  const TvClockHeader({
    super.key,
    required this.school,
    required this.onOpenSettings,
  });

  @override
  State<TvClockHeader> createState() => _TvClockHeaderState();
}

class _TvClockHeaderState extends State<TvClockHeader> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: offset supplied by server, refreshed with snapshot; no offline DST database.
    final schoolTime = _currentTime.toUtc().add(Duration(seconds: widget.school.utcOffsetSeconds));
    final timeStr = DateFormat('HH:mm:ss').format(schoolTime);
    String dateStr;
    try {
      dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(schoolTime);
    } catch (_) {
      dateStr = DateFormat('EEEE, d MMMM yyyy').format(schoolTime);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: TvColors.surface.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: TvColors.border, width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: School logo and name
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: TvColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TvColors.border),
                  ),
                  child: widget.school.logoUrl != null &&
                          widget.school.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget.school.logoUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.school,
                              color: TvColors.gold,
                              size: 34,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.school,
                          color: TvColors.gold,
                          size: 34,
                        ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.school.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TvColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: TvColors.emerald,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'AKADEMIHUB SMART CAMPUS DISPLAY',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: TvColors.primaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right: Live Clock & Settings Button
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: TvColors.gold,
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: TvColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              TvFocusable(
                autofocus: true,
                onSelect: widget.onOpenSettings,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TvColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TvColors.border),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
