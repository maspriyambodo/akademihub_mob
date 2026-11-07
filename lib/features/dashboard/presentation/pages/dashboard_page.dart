import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/admin_dashboard_widget.dart';
import '../widgets/guru_dashboard_widget.dart';
import '../widgets/siswa_dashboard_widget.dart';
import '../widgets/wali_dashboard_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final role = user?.role ?? 'unknown';
    final roleColors = AppColors.role(role);

    final roleLabel = switch (role) {
      'siswa' => 'RUANG SISWA',
      'guru' => 'RUANG GURU',
      'wali' => 'RUANG WALI',
      'admin' => 'RUANG ADMIN',
      'staff' => 'RUANG STAF',
      _ => 'BERANDA',
    };

    final topInset = MediaQuery.paddingOf(context).top;
    final pagePadding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // Educational Hero Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220 + topInset,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF071426),
                    Color(0xFF0C2340),
                    Color(0xFF093B57),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ExcludeSemantics(child: _HeroPatternPainter()),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding.left,
                        AppSpacing.xs,
                        pagePadding.right,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top bar: School Identity Pill & Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.20,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.school_outlined,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          (user?.tenant?.name ?? 'AkademiHub')
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 3,
                                        height: 3,
                                        decoration: const BoxDecoration(
                                          color: Colors.white60,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'SMT GENAP',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              // Notification Icon
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                  tooltip: 'Notifikasi',
                                  onPressed: () =>
                                      context.push(AppRoutes.notifications),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Profile Icon
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.account_circle_outlined,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                  tooltip: 'Profil',
                                  onPressed: () => context.go(AppRoutes.profil),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Role Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: roleColors.accent.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: roleColors.accent.withValues(
                                  alpha: 0.45,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: roleColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  roleLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Greeting
                          Text(
                            user != null
                                ? 'Halo, ${user.name}'
                                : 'AkademiHub',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Academic Subtitle Meta
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 13,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Siswa Aktif • TA 2026/2027',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content with Overlap
          Positioned.fill(
            top: 172 + topInset,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                child: BatasLebarKonten(
                  child: BlocBuilder<DashboardBloc, DashboardState>(
                    builder: (context, state) {
                      if (state is DashboardLoading ||
                          state is DashboardInitial) {
                        return const _DashboardSkeleton();
                      }

                      if (state is DashboardError) {
                        return _DashboardError(
                          message: state.message,
                          onRetry: () => context.read<DashboardBloc>().add(
                            DashboardRefreshRequested(),
                          ),
                        );
                      }

                      if (state is DashboardLoaded) {
                        final data = state.data;
                        final perms = user?.permissions ?? [];

                        return RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            context.read<DashboardBloc>().add(
                              DashboardRefreshRequested(),
                            );
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              pagePadding.left,
                              AppSpacing.lg,
                              pagePadding.right,
                              pagePadding.bottom + 96,
                            ),
                            child: switch (role) {
                              'siswa' => SiswaDashboardWidget(
                                data: data,
                                permissions: perms,
                              ),
                              'guru' => GuruDashboardWidget(
                                data: data,
                                permissions: perms,
                              ),
                              'wali' => WaliDashboardWidget(
                                data: data,
                                permissions: perms,
                              ),
                              'admin' || 'staff' => AdminDashboardWidget(
                                data: data,
                                permissions: perms,
                              ),
                              _ => const Text(
                                'Belum ada dashboard untuk peran ini.',
                              ),
                            },
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPatternPainter extends StatelessWidget {
  const _HeroPatternPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HeroPattern());
  }
}

class _HeroPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ambient glow orb 1 (top right)
    final orb1 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.22),
          radius: 96,
        ),
      );
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.22), 96, orb1);

    // Ambient glow orb 2 (bottom left accent)
    final orb2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.12, size.height * 0.85),
          radius: 80,
        ),
      );
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.85), 80, orb2);

    // Dynamic wave contour
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.32,
        size.width,
        size.height * 0.62,
      );
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);
    // ponytail: Shimmer skeleton placeholder; add staggered delay animation when widget load benchmarking justifies it.
    return Shimmer.fromColors(
      baseColor: AppColors.paperMuted,
      highlightColor: AppColors.paperBright,
      child: ListView(
        padding: EdgeInsets.fromLTRB(pad.left, AppSpacing.lg, pad.right, 96),
        children: [
          Row(
            children: List.generate(
              2,
              (_) => Expanded(
                child: Container(
                  height: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.paperBright,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.paperBright,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.paperBright,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 28,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Dashboard Belum Dapat Dimuat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
