import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/tv_snapshot.dart';
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
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    String dateStr;
    try {
      dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_currentTime);
    } catch (_) {
      dateStr = DateFormat('EEEE, d MMMM yyyy').format(_currentTime);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43).withAlpha(230),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF243B53), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: School logo and name
          Expanded(
            child: Row(
              children: [
                if (widget.school.logoUrl != null &&
                    widget.school.logoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.school.logoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school,
                        color: Color(0xFFE9A23B),
                        size: 36,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.school, color: Color(0xFFE9A23B), size: 36),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    widget.school.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
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
                      color: Color(0xFFE9A23B),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              TvFocusable(
                onSelect: widget.onOpenSettings,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF243B53),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 22,
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
