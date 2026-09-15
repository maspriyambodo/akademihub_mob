import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../bloc/tv_auth_bloc.dart';
import '../bloc/tv_auth_event.dart';
import '../bloc/tv_auth_state.dart';
import '../widgets/tv_focusable.dart';

class TvPairingPage extends StatelessWidget {
  const TvPairingPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<TvAuthBloc>()) {
      return const Scaffold(
        key: Key('tv_pairing_page'),
        backgroundColor: Color(0xFF102A43),
        body: SizedBox.shrink(),
      );
    }
    return BlocProvider(
      create: (_) => sl<TvAuthBloc>()..add(const TvAuthStarted()),
      child: const _TvPairingView(),
    );
  }
}

class _TvPairingView extends StatefulWidget {
  const _TvPairingView();

  @override
  State<_TvPairingView> createState() => _TvPairingViewState();
}

class _TvPairingViewState extends State<_TvPairingView> with WidgetsBindingObserver {
  bool _exitDialogOpen = false;

  Future<void> _confirmExit() async {
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    final exit = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Keluar dari pairing TV?'),
      actions: [
        TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
      ],
    ));
    _exitDialogOpen = false;
    if (exit == true) await SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      context.read<TvAuthBloc>().resumePolling();
    } else {
      context.read<TvAuthBloc>().pausePolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TvAuthBloc, TvAuthState>(
      listener: (context, state) {
        if (state is TvAuthPaired) {
          context.go(AppRoutes.tvSignage);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) { if (!didPop) _confirmExit(); },
          child: Scaffold(
          key: const Key('tv_pairing_page'),
          backgroundColor: const Color(0xFF102A43),
          body: SafeArea(minimum: const EdgeInsets.all(48), child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: _buildBody(context, state),
              ),
            ),
          )),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TvAuthState state) {
    if (state is TvAuthChecking || state is TvPairingLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFFE9A23B)),
          SizedBox(height: 24),
          Text(
            'Menyiapkan sesi pairing...',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      );
    }

    if (state is TvPairingPending) {
      final session = state.session;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'HUBUNGKAN LAYAR ANDROID TV',
            style: TextStyle(
              color: Color(0xFFBFE8DF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF087F75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              session.userCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 54,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Buka menu Kelola TV pada web admin sekolah lalu masukkan kode di atas.\n'
            'Atau buka: ${session.verificationUrl}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE9A23B),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Menunggu persetujuan admin...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      );
    }

    if (state is TvPairingExpired ||
        state is TvPairingDenied ||
        state is TvAuthFailure) {
      final (title, message) = switch (state) {
        TvPairingExpired() => (
          'Kode Kedaluwarsa',
          'Kode pairing telah kedaluwarsa.',
        ),
        TvPairingDenied(:final message) => ('Permintaan Ditolak', message),
        TvAuthFailure(:final message) => ('Gagal Menghubungkan', message),
        _ => ('', ''),
      };

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE9A23B), size: 56),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          TvFocusable(
            autofocus: true,
            onSelect: () =>
                context.read<TvAuthBloc>().add(const TvPairingRetryRequested()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF087F75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
