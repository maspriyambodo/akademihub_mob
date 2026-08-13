import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/siswa_dashboard_widget.dart';
import '../widgets/guru_dashboard_widget.dart';
import '../widgets/wali_dashboard_widget.dart';
import '../widgets/admin_dashboard_widget.dart';

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
    final user = (context.watch<AuthBloc>().state as AuthAuthenticated?)?.user;
    final roleLabel = switch (user?.role) {
      'siswa' => 'Portal Siswa',
      'guru' => 'Portal Guru',
      'wali' => 'Portal Wali',
      _ => 'Portal Admin',
    };

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              roleLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (user != null)
              Text(
                user.name,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          PopupMenuButton<_DashboardAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              if (action == _DashboardAction.logout) {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _DashboardAction.logout,
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Keluar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const _LoadingSkeleton();
          }

          if (state is DashboardError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<DashboardBloc>().add(DashboardLoadRequested()),
            );
          }

          if (state is DashboardLoaded) {
            final data = state.data;
            final pad = Responsive.pagePadding(context);
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(DashboardRefreshRequested());
              },
              child: BatasLebarKonten(
                child: ListView(
                  padding: pad,
                  children: [
                    if (data.role == 'siswa')
                      SiswaDashboardWidget(
                        data: data,
                        permissions: user?.permissions ?? const [],
                      )
                    else if (data.role == 'guru')
                      GuruDashboardWidget(
                        data: data,
                        permissions: user?.permissions ?? const [],
                      )
                    else if (data.role == 'wali')
                      WaliDashboardWidget(
                        data: data,
                        permissions: user?.permissions ?? const [],
                      )
                    else
                      AdminDashboardWidget(
                        data: data,
                        permissions: user?.permissions ?? const [],
                      ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);
    return BatasLebarKonten(
      child: ListView(
        padding: pad,
        children: [
          Container(
            height: 28,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: Responsive.gridDelegate(context, tinggi: 140),
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Dashboard',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
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

enum _DashboardAction { logout }
