import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/rapor_entity.dart';
import '../bloc/rapor_bloc.dart';
import 'rapor_detail_page.dart';

class RaporPage extends StatelessWidget {
  const RaporPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RaporBloc>(),
      child: const _RaporView(),
    );
  }
}

class _RaporView extends StatefulWidget {
  const _RaporView();

  @override
  State<_RaporView> createState() => _RaporViewState();
}

class _RaporViewState extends State<_RaporView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _role = '';
  bool _canExport = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final role = (user.role ?? 'admin').toLowerCase();
      final profileId = user.profile?['id'] as int?;

      setState(() {
        _role = role;
        _canExport = user.hasPermission('rapor.export');
      });

      context.read<RaporBloc>().add(
        RaporLoadRequested(role: role, profileId: profileId),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<RaporBloc>().add(RaporSearchChanged(value));
    });
  }

  void _openDetail(RaporEntity rapor) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RaporDetailPage(rapor: rapor, canExport: _canExport),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Role siswa hanya melihat rapornya sendiri → kolom pencarian tidak perlu.
    final showSearch = _role.isNotEmpty && _role != 'siswa';

    return Scaffold(
      appBar: AppBar(title: const Text('Rapor'), centerTitle: true),
      body: Column(
        children: [
          if (showSearch)
            _SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          Expanded(
            child: BlocBuilder<RaporBloc, RaporState>(
              builder: (context, state) {
                if (state is RaporInitial || state is RaporLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is RaporError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context.read<RaporBloc>().add(
                      const RaporRefreshRequested(),
                    ),
                  );
                }
                if (state is RaporLoaded) {
                  final pad = Responsive.pagePadding(context);
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.lebarKontenMaks(context),
                      ),
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context.read<RaporBloc>().add(
                            const RaporRefreshRequested(),
                          );
                        },
                        child: state.items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: Responsive.tinggiSheet(
                                      context,
                                      rasio: 0.6,
                                    ),
                                    child: _EmptyView(
                                      message: state.search.trim().isNotEmpty
                                          ? 'Tidak ada rapor yang cocok dengan pencarian'
                                          : 'Belum ada data rapor',
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  pad.left,
                                  12,
                                  pad.right,
                                  24,
                                ),
                                itemCount: state.items.length,
                                itemBuilder: (_, i) {
                                  final item = state.items[i];
                                  return _RaporCard(
                                    rapor: item,
                                    showSiswa: !state.isSiswaMode,
                                    onTap: () => _openDetail(item),
                                  );
                                },
                              ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.pagePadding(context).left;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari nama siswa...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, child) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClear,
                  ),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

// ── Rapor Card ───────────────────────────────────────────────────────────────

class _RaporCard extends StatelessWidget {
  final RaporEntity rapor;
  final bool showSiswa;
  final VoidCallback onTap;

  const _RaporCard({
    required this.rapor,
    required this.showSiswa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rata = rapor.rataRata;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(Responsive.isCompact(context) ? 10 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nilai rata-rata
              Container(
                width: Responsive.isCompact(context) ? 52 : 60,
                height: Responsive.isCompact(context) ? 52 : 60,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _nilaiColor(rata).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _nilaiColor(rata).withAlpha(70)),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rata != null ? rata.toStringAsFixed(1) : '-',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _nilaiColor(rata),
                        ),
                      ),
                      Text(
                        'rata-rata',
                        maxLines: 1,
                        style: TextStyle(fontSize: 8, color: _nilaiColor(rata)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: Responsive.isCompact(context) ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSiswa) ...[
                      Text(
                        rapor.siswaNama ?? 'Siswa',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      rapor.labelPeriode,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: showSiswa ? 12 : 14,
                        fontWeight: showSiswa
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: showSiswa
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, c) => Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (rapor.kelas != null && rapor.kelas!.isNotEmpty)
                            _Chip(
                              icon: Icons.class_outlined,
                              label: rapor.kelas!,
                              color: AppColors.info,
                              maxWidth: c.maxWidth,
                            ),
                          if (rapor.siswaNis != null && showSiswa)
                            _Chip(
                              icon: Icons.badge_outlined,
                              label: 'NIS ${rapor.siswaNis}',
                              color: AppColors.textSecondary,
                              maxWidth: c.maxWidth,
                            ),
                          if (rapor.peringkat != null)
                            _Chip(
                              icon: Icons.emoji_events_outlined,
                              label: 'Peringkat ${rapor.peringkat}',
                              color: AppColors.warning,
                              maxWidth: c.maxWidth,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _nilaiColor(double? nilai) {
    if (nilai == null) return AppColors.textSecondary;
    if (nilai >= 90) return AppColors.success;
    if (nilai >= 75) return AppColors.info;
    if (nilai >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  /// Batas lebar chip agar label panjang tidak meluber keluar `Wrap`.
  final double? maxWidth;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth != null && maxWidth!.isFinite
            ? maxWidth!
            : double.infinity,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context) + const EdgeInsets.all(16),
      child: Center(
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
            const SizedBox(height: 20),
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

// ── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: Responsive.pagePadding(context) + const EdgeInsets.all(16),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
