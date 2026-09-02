import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
    final role = user?.role ?? 'admin';
    final roleColors = AppColors.role(role);

    final roleLabel = switch (role) {
      'siswa' => 'RUANG SISWA',
      'guru' => 'RUANG GURU',
      'wali' => 'RUANG WALI',
      _ => 'RUANG ADMIN',
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
              height: 200 + topInset,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark,
                    Color.alphaBlend(
                      roleColors.accent.withValues(alpha: 0.6),
                      AppColors.primaryDark,
                    ),
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
                        AppSpacing.sm,
                        pagePadding.right,
                        AppSpacing.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  roleLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: roleColors.container,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user != null
                                      ? 'Halo, ${user.name}'
                                      : 'AkademiHub',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                            tooltip: 'Notifikasi',
                            onPressed: () =>
                                context.push(AppRoutes.notifications),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.account_circle_outlined,
                              color: Colors.white,
                            ),
                            tooltip: 'Profil',
                            onPressed: () => context.go(AppRoutes.profil),
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
            top: 130 + topInset,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
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
                              _ => AdminDashboardWidget(
                                data: data,
                                permissions: perms,
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
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paint,
    );

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.25),
      64,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);
    return ListView(
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
