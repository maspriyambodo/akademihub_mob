import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../theme/tv_theme.dart';

class TvTicker extends StatefulWidget {
  final List<TvAnnouncementItem> announcements;

  const TvTicker({super.key, required this.announcements});

  @override
  State<TvTicker> createState() => _TvTickerState();
}

class _TvTickerState extends State<TvTicker> {
  late final ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (current >= maxExtent) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(current + 1.2);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final tickerText = widget.announcements
        .map((a) => '📢  ${a.title}: ${a.body}')
        .join('    •    ');

    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: TvColors.backgroundDark,
        border: Border(
          top: BorderSide(color: TvColors.border, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            color: TvColors.primary,
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'INFO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      tickerText,
                      style: const TextStyle(
                        color: TvColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
