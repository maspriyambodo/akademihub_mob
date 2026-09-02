import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_metric_tile.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/nilai_bloc.dart';
import '../../domain/entities/nilai_entity.dart';
import '../../domain/entities/nilai_summary_entity.dart';

class NilaiPage extends StatelessWidget {
  const NilaiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NilaiBloc>(),
      child: const NilaiView(),
    );
  }
}

class NilaiView extends StatefulWidget {
  const NilaiView({super.key});

  @override
  State<NilaiView> createState() => _NilaiViewState();
}

class _NilaiViewState extends State<NilaiView> {
  final TextEditingController _searchController = TextEditingController();
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        final profileId = user.profile?['id'] as int?;
        setState(() {
          _canCreate = user.hasPermission('nilai.create');
          _canUpdate = user.hasPermission('nilai.update');
          _canDelete = user.hasPermission('nilai.delete');
        });
        context.read<NilaiBloc>().add(
          NilaiLoadRequested(
            role: user.role ?? 'unknown',
            profileId: profileId,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Nilai'), centerTitle: true),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Nilai'),
            )
          : null,
      body: BlocConsumer<NilaiBloc, NilaiState>(
        listenWhen: (_, state) =>
            state is NilaiActionSuccess || state is NilaiActionFailure,
        listener: (context, state) {
          final message = state is NilaiActionSuccess
              ? state.message
              : (state as NilaiActionFailure).message;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: state is NilaiActionSuccess
                    ? AppColors.success
                    : AppColors.error,
              ),
            );
        },
        buildWhen: (_, state) =>
            state is! NilaiActionSuccess && state is! NilaiActionFailure,
        builder: (context, state) {
          if (state is NilaiLoading || state is NilaiInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NilaiError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<NilaiBloc>().add(const NilaiRefreshRequested()),
            );
          }
          if (state is NilaiLoaded) {
            return _LoadedView(
              state: state,
              searchController: _searchController,
              canUpdate: _canUpdate,
              canDelete: _canDelete,
              onEdit: (item) => _openForm(context, initial: item),
              onDelete: (item) => _confirmDelete(context, item),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {NilaiEntity? initial}) async {
    final state = context.read<NilaiBloc>().state;
    if (state is! NilaiLoaded) return;
    final result = await showModalBottomSheet<NilaiFormValue>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NilaiFormSheet(items: state.items, initial: initial),
    );
    if (result == null || !context.mounted) return;
    final bloc = context.read<NilaiBloc>();
    if (initial == null) {
      bloc.add(
        NilaiCreateRequested(
          siswaId: result.siswaId!,
          ujianId: result.ujianId!,
          nilai: result.nilai,
          keterangan: result.keterangan,
        ),
      );
    } else {
      bloc.add(
        NilaiUpdateRequested(
          id: initial.id,
          nilai: result.nilai,
          keterangan: result.keterangan,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, NilaiEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus nilai?'),
        content: Text('${item.siswaNama ?? 'Siswa'}: ${item.judul}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<NilaiBloc>().add(NilaiDeleteRequested(item.id));
    }
  }
}

// ── Loaded View ───────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final NilaiLoaded state;
  final TextEditingController searchController;
  final bool canUpdate;
  final bool canDelete;
  final ValueChanged<NilaiEntity> onEdit;
  final ValueChanged<NilaiEntity> onDelete;

  const _LoadedView({
    required this.state,
    required this.searchController,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NilaiBloc>();
    final showSemesterFilter =
        state.semesterOptions.isNotEmpty && !state.isUjianMode;

    return Column(
      children: [
        if (state.showSearch)
          _SearchBar(
            controller: searchController,
            onChanged: (value) => bloc.add(NilaiSearchChanged(value)),
          ),
        if (state.isGuruMode && state.ujianOptions.isNotEmpty)
          _UjianSelector(
            options: state.ujianOptions,
            selectedId: state.selectedUjianId,
            onChanged: (id) => bloc.add(NilaiUjianSelected(id)),
          ),
        if (showSemesterFilter)
          _SemesterFilter(
            options: state.semesterOptions,
            selected: state.selectedSemester,
            onChanged: (value) => bloc.add(NilaiSemesterChanged(value)),
          ),
        Expanded(
          child: BatasLebarKonten(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                bloc.add(const NilaiRefreshRequested());
              },
              child: _buildContent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final items = state.items;
    final pagePadding = Responsive.pagePadding(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (state.isRingkasanMode)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              AppSpacing.md,
              pagePadding.right,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _SummaryHeader(summary: state.summary),
            ),
          ),
        if (state.isUjianMode)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              AppSpacing.md,
              pagePadding.right,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _UjianBanner(
                label: state.selectedUjian?.label ?? 'Ujian terpilih',
                subtitle: state.selectedUjian?.subtitle ?? '',
                jumlah: items.length,
              ),
            ),
          ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(message: _emptyMessage()),
          )
        else if (state.isRingkasanMode)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              AppSpacing.md,
              pagePadding.right,
              AppSpacing.xxl,
            ),
            sliver: _buildGroupedList(items),
          )
        else ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              AppSpacing.md,
              pagePadding.right,
              AppSpacing.xs,
            ),
            sliver: SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Daftar Nilai',
                eyebrow: 'Penilaian Siswa',
                actionLabel: '${items.length} Catatan',
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pagePadding.left),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _NilaiSiswaTile(
                    item: items[i],
                    canUpdate: canUpdate,
                    canDelete: canDelete,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ),
                childCount: items.length,
              ),
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
      ],
    );
  }

  Widget _buildGroupedList(List<NilaiEntity> items) {
    final groups = _groupByMapel(items);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _MapelGroupCard(
            mapel: groups[i].key,
            items: groups[i].value,
            showSiswa: state.role != 'siswa',
          ),
        ),
        childCount: groups.length,
      ),
    );
  }

  String _emptyMessage() {
    if (state.searchQuery.trim().isNotEmpty) {
      return 'Tidak ada nilai yang cocok dengan pencarian';
    }
    if (state.selectedSemester != null) {
      return 'Belum ada nilai pada semester ini';
    }
    if (state.isUjianMode) {
      return 'Belum ada nilai pada ujian ini';
    }
    return 'Belum ada data nilai';
  }
}

// ── Pengelompokan per mata pelajaran ──────────────────────────────────────────

List<MapEntry<String, List<NilaiEntity>>> _groupByMapel(
  List<NilaiEntity> items,
) {
  final map = <String, List<NilaiEntity>>{};
  for (final item in items) {
    map.putIfAbsent(item.mapelLabel, () => <NilaiEntity>[]).add(item);
  }
  final keys = map.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return keys.map((k) => MapEntry(k, map[k]!)).toList();
}

// ── Helper warna & format ─────────────────────────────────────────────────────

AppStatusTone _nilaiTone(double? nilai) {
  if (nilai == null) return AppStatusTone.neutral;
  if (nilai >= 85) return AppStatusTone.success;
  if (nilai >= 75) return AppStatusTone.info;
  if (nilai >= 60) return AppStatusTone.warning;
  return AppStatusTone.error;
}

String _predikat(double? nilai) {
  if (nilai == null) return '-';
  if (nilai >= 85) return 'A';
  if (nilai >= 75) return 'B';
  if (nilai >= 60) return 'C';
  return 'D';
}

String _formatNilai(double? nilai) {
  if (nilai == null) return '-';
  if (nilai == nilai.roundToDouble()) return nilai.toInt().toString();
  return nilai.toStringAsFixed(1);
}

const List<String> _monthsShort = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String? _formatTanggal(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  return '${date.day} ${_monthsShort[date.month]} ${date.year}';
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.pagePadding(context);
    return Container(
      color: AppColors.paperBright,
      padding: EdgeInsets.fromLTRB(
        pagePadding.left,
        AppSpacing.xs,
        pagePadding.right,
        AppSpacing.xs,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari nama siswa / mata pelajaran',
          prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
    );
  }
}

// ── Pemilih Ujian (role guru) ─────────────────────────────────────────────────

class _UjianSelector extends StatelessWidget {
  final List<NilaiUjianOption> options;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _UjianSelector({
    required this.options,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.pagePadding(context);
    return Container(
      color: AppColors.paperBright,
      padding: EdgeInsets.fromLTRB(
        pagePadding.left,
        0,
        pagePadding.right,
        AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: AppColors.paper,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: selectedId,
            isExpanded: true,
            hint: const Text('Pilih ujian', style: TextStyle(fontSize: 13)),
            icon: const Icon(Icons.expand_more, color: AppColors.inkMuted),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Semua nilai', style: TextStyle(fontSize: 13)),
              ),
              ...options.map(
                (o) => DropdownMenuItem<int?>(
                  value: o.id,
                  child: Text(
                    o.subtitle.isEmpty ? o.label : '${o.label} — ${o.subtitle}',
                    softWrap: true,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _UjianBanner extends StatelessWidget {
  final String label;
  final String subtitle;
  final int jumlah;

  const _UjianBanner({
    required this.label,
    required this.subtitle,
    required this.jumlah,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      accentColor: AppColors.primary,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '$jumlah siswa dinilai',
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

// ── Filter Semester ───────────────────────────────────────────────────────────

class _SemesterFilter extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _SemesterFilter({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.pagePadding(context);
    return Container(
      color: AppColors.paperBright,
      padding: EdgeInsets.fromLTRB(
        pagePadding.left,
        0,
        pagePadding.right,
        AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: AppColors.paper,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selected,
            isExpanded: true,
            icon: const Icon(Icons.expand_more, color: AppColors.inkMuted),
            hint: const Text('Pilih semester', style: TextStyle(fontSize: 13)),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua semester', style: TextStyle(fontSize: 13)),
              ),
              ...options.map(
                (o) => DropdownMenuItem<String?>(
                  value: o,
                  child: Text(o, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// ── Ringkasan ─────────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final NilaiSummaryEntity summary;
  const _SummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final rata = summary.rataRata;
    final tone = _nilaiTone(rata);

    return AppSurfaceCard(
      accentColor: AppColors.semantic(tone).accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.semantic(tone).container,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatNilai(rata),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.semantic(tone).onContainer,
                      ),
                    ),
                    Text(
                      'Predikat ${_predikat(rata)}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.semantic(tone).onContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rata-rata Nilai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.total} catatan nilai terdaftar',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Mapel',
                  value: '${summary.jumlahMapel}',
                  icon: Icons.menu_book_outlined,
                  tone: AppStatusTone.neutral,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppMetricTile(
                  label: 'Tertinggi',
                  value: _formatNilai(summary.tertinggi),
                  icon: Icons.arrow_upward_rounded,
                  tone: AppStatusTone.success,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppMetricTile(
                  label: 'Terendah',
                  value: _formatNilai(summary.terendah),
                  icon: Icons.arrow_downward_rounded,
                  tone: AppStatusTone.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Kartu grup per mata pelajaran ─────────────────────────────────────────────

class _MapelGroupCard extends StatelessWidget {
  final String mapel;
  final List<NilaiEntity> items;
  final bool showSiswa;

  const _MapelGroupCard({
    required this.mapel,
    required this.items,
    required this.showSiswa,
  });

  double? get _rataMapel {
    final values = items.map((e) => e.nilai).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    final rata = _rataMapel;
    final tone = _nilaiTone(rata);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mapel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(label: 'Rata: ${_formatNilai(rata)}', tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 1, color: AppColors.line),
          ...items.map((item) => _NilaiRow(item: item, showSiswa: showSiswa)),
        ],
      ),
    );
  }
}

class _NilaiRow extends StatelessWidget {
  final NilaiEntity item;
  final bool showSiswa;

  const _NilaiRow({required this.item, required this.showSiswa});

  @override
  Widget build(BuildContext context) {
    final jenis =
        (item.jenisPenilaian != null && item.jenisPenilaian!.isNotEmpty)
        ? item.jenisPenilaian!
        : null;
    final tanggal = _formatTanggal(item.tanggalUjian);
    final semester = item.semesterDetailLabel ?? item.semesterLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (showSiswa && item.siswaNama != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    item.siswaNama!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
                if (jenis != null || semester != null || tanggal != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [?jenis, ?semester, ?tanggal].join(' · '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _NilaiBadge(nilai: item.nilai),
        ],
      ),
    );
  }
}

// ── Baris nilai untuk guru / admin ────────────────────────────────────────────

class _NilaiSiswaTile extends StatelessWidget {
  final NilaiEntity item;
  final bool canUpdate;
  final bool canDelete;
  final ValueChanged<NilaiEntity> onEdit;
  final ValueChanged<NilaiEntity> onDelete;

  const _NilaiSiswaTile({
    required this.item,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mapel = (item.mapelNama != null && item.mapelNama!.trim().isNotEmpty)
        ? item.mapelNama!.trim()
        : item.judul;
    final jenis =
        (item.jenisPenilaian != null && item.jenisPenilaian!.trim().isNotEmpty)
        ? item.jenisPenilaian!.trim()
        : null;
    final semester = item.semesterDetailLabel ?? item.semesterLabel;
    final kelas = (item.kelasNama != null && item.kelasNama!.trim().isNotEmpty)
        ? item.kelasNama!.trim()
        : null;

    final tone = _nilaiTone(item.nilai);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.semantic(tone).container,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                _predikat(item.nilai),
                style: TextStyle(
                  color: AppColors.semantic(tone).onContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.siswaNama ?? item.judul,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (item.siswaNis != null && item.siswaNis!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    'NIS ${item.siswaNis}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  [mapel, ?jenis, ?kelas, ?semester].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            children: [
              _NilaiBadge(nilai: item.nilai),
              if (canUpdate || canDelete)
                PopupMenuButton<String>(
                  tooltip: 'Aksi nilai',
                  onSelected: (action) =>
                      action == 'edit' ? onEdit(item) : onDelete(item),
                  itemBuilder: (_) => [
                    if (canUpdate)
                      const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NilaiBadge extends StatelessWidget {
  final double? nilai;

  const _NilaiBadge({required this.nilai});

  @override
  Widget build(BuildContext context) {
    final tone = _nilaiTone(nilai);
    final text = _formatNilai(nilai);

    return AppStatusBadge(label: text, tone: tone);
  }
}

// ── Form Nilai Sheet ─────────────────────────────────────────────────────────

class NilaiFormValue {
  final int? siswaId;
  final int? ujianId;
  final double nilai;
  final String? keterangan;

  const NilaiFormValue({
    this.siswaId,
    this.ujianId,
    required this.nilai,
    this.keterangan,
  });
}

class NilaiFormSheet extends StatefulWidget {
  final List<NilaiEntity> items;
  final NilaiEntity? initial;

  const NilaiFormSheet({super.key, required this.items, this.initial});

  @override
  State<NilaiFormSheet> createState() => _NilaiFormSheetState();
}

class _NilaiFormSheetState extends State<NilaiFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nilaiController = TextEditingController();
  final _keteranganController = TextEditingController();
  int? _selectedSiswaId;
  int? _selectedUjianId;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nilaiController.text = widget.initial!.nilai?.toString() ?? '';
      _keteranganController.text = widget.initial!.keterangan ?? '';
      _selectedSiswaId = widget.initial!.siswaId;
      _selectedUjianId = widget.initial!.ujianId;
    }
  }

  @override
  void dispose() {
    _nilaiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final nilai = double.tryParse(_nilaiController.text.trim());
    if (nilai == null) return;

    Navigator.pop(
      context,
      NilaiFormValue(
        siswaId: _selectedSiswaId,
        ujianId: _selectedUjianId,
        nilai: nilai,
        keterangan: _keteranganController.text.trim().isEmpty
            ? null
            : _keteranganController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'Tambah Nilai' : 'Ubah Nilai',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('nilai_form_nilai'),
                controller: _nilaiController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nilai (0 - 100)',
                  hintText: 'Contoh: 85',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Masukkan nilai 0 sampai 100';
                  }
                  final n = double.tryParse(v.trim());
                  if (n == null || n < 0 || n > 100) {
                    return 'Masukkan nilai 0 sampai 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('nilai_form_keterangan'),
                controller: _keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('nilai_form_submit'),
                  onPressed: _submit,
                  child: const Text('Simpan'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error View ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.grade_outlined,
              size: 48,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
            ),
          ],
        ),
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
                Icons.error_outline_rounded,
                size: 28,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gagal Memuat Nilai',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
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
