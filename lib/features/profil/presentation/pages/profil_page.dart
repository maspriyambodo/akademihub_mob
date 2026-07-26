import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profil_bloc.dart';
import '../widgets/data_diri_card.dart';
import '../widgets/perangkat_card.dart';
import '../widgets/profil_header.dart';
import '../widgets/profil_info_card.dart';
import '../widgets/sekolah_card.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfilBloc>(),
      child: const _ProfilView(),
    );
  }
}

class _ProfilView extends StatefulWidget {
  const _ProfilView();

  @override
  State<_ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<_ProfilView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _muat();
    });
  }

  void _muat() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    context.read<ProfilBloc>().add(
      ProfilLoadRequested(
        userId: user.id,
        // `GET /sekolah/{id}` & `GET /sekolah/uuid/{uuid}` dijaga
        // PermissionMiddleware:sekolah.view
        bisaLihatSekolah: user.hasPermission('sekolah.view'),
        // `GET /admin/user-devices/user/{userId}` dijaga
        // PermissionMiddleware:users.view — siswa & wali tidak punya.
        bisaLihatPerangkat: user.hasPermission('users.view'),
      ),
    );
  }

  Future<void> _refresh() async {
    context.read<ProfilBloc>().add(const ProfilRefreshRequested());
  }

  Future<void> _konfirmasiLogout() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Keluar dari Akun'),
        content: const Text(
          'Anda yakin ingin keluar? Anda harus masuk kembali untuk '
          'mengakses aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (setuju != true || !mounted) return;
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), centerTitle: true),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const _ErrorView(
              message: 'Sesi tidak ditemukan. Silakan masuk kembali.',
            );
          }

          final user = authState.user;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                ProfilHeader(user: user),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: BlocBuilder<ProfilBloc, ProfilState>(
                    builder: (context, state) => _Konten(
                      user: user,
                      state: state,
                      onRetry: _muat,
                      onLogout: _konfirmasiLogout,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Konten di bawah header ───────────────────────────────────────────────────

class _Konten extends StatelessWidget {
  final UserEntity user;
  final ProfilState state;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  const _Konten({
    required this.user,
    required this.state,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Data diri selalu tersedia — sumbernya AuthBloc, bukan panggilan API
        // tambahan.
        DataDiriCard(user: user),

        if (s is ProfilLoading || s is ProfilInitial) ...[
          const _KartuMemuat(
            judul: 'Sekolah',
            ikon: Icons.account_balance_outlined,
          ),
          const _KartuMemuat(
            judul: 'Tentang Aplikasi',
            ikon: Icons.info_outline,
          ),
        ] else if (s is ProfilError) ...[
          ProfilInfoCard(
            judul: 'Informasi Tambahan',
            ikon: Icons.error_outline,
            warnaIkon: AppColors.error,
            children: [
              ProfilCardMessage(
                ikon: Icons.cloud_off_outlined,
                pesan: s.message,
                warna: AppColors.error,
                onRetry: onRetry,
              ),
            ],
          ),
        ] else if (s is ProfilLoaded) ...[
          SekolahCard(
            sekolah: s.sekolah,
            dariCache: s.sekolahDariCache,
            error: s.sekolahError,
            onRetry: onRetry,
          ),
          if (s.perangkatTersedia)
            PerangkatCard(
              items: s.perangkat,
              error: s.perangkatError,
              onRetry: onRetry,
            ),
          _TentangAplikasiCard(state: s),
        ],

        const SizedBox(height: 8),
        _TombolLogout(onPressed: onLogout),
      ],
    );
  }
}

// ── Tentang Aplikasi ─────────────────────────────────────────────────────────

class _TentangAplikasiCard extends StatelessWidget {
  final ProfilLoaded state;

  const _TentangAplikasiCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final info = state.appInfo;

    return ProfilInfoCard(
      judul: 'Tentang Aplikasi',
      ikon: Icons.info_outline,
      warnaIkon: AppColors.accent,
      children: info == null
          ? const [
              ProfilCardMessage(
                ikon: Icons.info_outline,
                pesan: 'Informasi aplikasi tidak tersedia',
              ),
            ]
          : [
              ProfilInfoRow(
                ikon: Icons.apps_outlined,
                label: 'Aplikasi',
                nilai: info.namaAplikasi,
              ),
              ProfilInfoRow(
                ikon: Icons.numbers_outlined,
                label: 'Versi',
                nilai: info.versiLengkap,
              ),
              if (info.packageName.isNotEmpty)
                ProfilInfoRow(
                  ikon: Icons.inventory_2_outlined,
                  label: 'Paket',
                  nilai: info.packageName,
                ),
            ],
    );
  }
}

// ── Kartu placeholder saat memuat ────────────────────────────────────────────

class _KartuMemuat extends StatelessWidget {
  final String judul;
  final IconData ikon;

  const _KartuMemuat({required this.judul, required this.ikon});

  @override
  Widget build(BuildContext context) {
    return ProfilInfoCard(
      judul: judul,
      ikon: ikon,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tombol logout ────────────────────────────────────────────────────────────

class _TombolLogout extends StatelessWidget {
  final VoidCallback onPressed;

  const _TombolLogout({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout),
        label: const Text('Keluar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message}) : onRetry = null;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
