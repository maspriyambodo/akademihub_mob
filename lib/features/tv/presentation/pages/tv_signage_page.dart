import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../bloc/tv_signage_bloc.dart';
import '../bloc/tv_signage_event.dart';
import '../bloc/tv_signage_state.dart';
import '../widgets/tv_clock_header.dart';
import '../widgets/tv_focusable.dart';
import '../widgets/tv_settings_dialog.dart';
import '../widgets/tv_slide_announcement.dart';
import '../widgets/tv_slide_calendar.dart';
import '../widgets/tv_slide_schedule.dart';
import '../widgets/tv_status_badge.dart';
import '../widgets/tv_ticker.dart';

class TvSignagePage extends StatelessWidget {
  const TvSignagePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<TvSignageBloc>()) {
      return const Scaffold(
        key: Key('tv_signage_page'),
        backgroundColor: Colors.black,
        body: SizedBox.shrink(),
      );
    }
    return BlocProvider(
      create: (_) => sl<TvSignageBloc>()..add(const TvSignageStarted()),
      child: const _TvSignageView(),
    );
  }
}

class _TvSignageView extends StatefulWidget {
  const _TvSignageView();

  @override
  State<_TvSignageView> createState() => _TvSignageViewState();
}

class _TvSignageViewState extends State<_TvSignageView> with WidgetsBindingObserver {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<TvSignageBloc>();
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      bloc.resume();
    } else {
      bloc.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _confirmExit() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final exit = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Keluar dari layar TV?'),
      actions: [
        TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
      ],
    ));
    _dialogOpen = false;
    if (exit == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TvSignageBloc, TvSignageState>(
      listener: (context, state) {
        if (state is TvSignageAuthExpired) {
          context.go(AppRoutes.tvPairing);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) { if (!didPop) _confirmExit(); },
          child: Scaffold(
          key: const Key('tv_signage_page'),
          backgroundColor: const Color(0xFF0A1929),
          body: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                final bloc = context.read<TvSignageBloc>();
                bloc.interact();
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  bloc.add(TvSignageNextSlideTicked(direction: event.logicalKey == LogicalKeyboardKey.arrowLeft ? -1 : 1));
                  return KeyEventResult.handled;
                }
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                      event.logicalKey == LogicalKeyboardKey.f10)) {
                if (state is TvSignageReady) {
                  _openSettings(context, state.snapshot.device);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: SafeArea(minimum: const EdgeInsets.all(48), child: _buildBody(context, state)),
          ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TvSignageState state) {
    if (state is TvSignageLoading || state is TvSignageInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF087F75)),
      );
    }

    if (state is TvSignageOffline) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Color(0xFFE9A23B), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Mode Offline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            TvFocusable(
              autofocus: true,
              onSelect: () => context.read<TvSignageBloc>().add(
                const TvSignageRefreshRequested(),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF087F75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Muat Ulang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is TvSignageReady) {
      final snapshot = state.snapshot;
      return Column(
        children: [
          TvClockHeader(
            school: snapshot.school,
            onOpenSettings: () => _openSettings(context, snapshot.device),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  TvStatusBadge(
                    device: snapshot.device,
                    isOffline: state.isOffline,
                    attendance: snapshot.settings.showAttendance
                        ? snapshot.attendance
                        : null,
                  ),
                  Text('Sinkronisasi terakhir: ${state.lastSyncedAt.toUtc().toIso8601String()} (UTC)', style: const TextStyle(color: Colors.white70, fontSize: 22)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildSlide(snapshot, state.currentSlideIndex),
                  ),
                ],
              ),
            ),
          ),
          TvTicker(announcements: snapshot.announcements),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSlide(TvSnapshot snapshot, int slideIndex) {
    final slides = <Widget>[];
    if (snapshot.schedule.isNotEmpty) {
      slides.add(TvSlideSchedule(schedule: snapshot.schedule));
    }
    for (final ann in snapshot.announcements) {
      slides.add(TvSlideAnnouncement(announcement: ann));
    }
    if (snapshot.calendar.isNotEmpty) {
      slides.add(TvSlideCalendar(calendar: snapshot.calendar, utcOffsetSeconds: snapshot.school.utcOffsetSeconds));
    }

    if (slides.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada agenda.',
          style: TextStyle(color: Colors.white60, fontSize: 20),
        ),
      );
    }

    final safeIndex = slideIndex % slides.length;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: KeyedSubtree(
        key: ValueKey('slide_$safeIndex'),
        child: slides[safeIndex],
      ),
    );
  }

  Future<void> _openSettings(BuildContext context, TvDeviceSummary device) async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    context.read<TvSignageBloc>().interact();
    await TvSettingsDialog.show(
      context,
      device: device,
      onUnpair: () =>
          context.read<TvSignageBloc>().add(const TvSignageUnpairConfirmed()),
    );
    _dialogOpen = false;
    if (mounted) context.read<TvSignageBloc>().interact();
  }
}
