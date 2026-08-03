import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
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
      child: const _NilaiView(),
    );
  }
}

class _NilaiView extends StatefulWidget {
  const _NilaiView();

  @override
  State<_NilaiView> createState() => _NilaiViewState();
}

class _NilaiViewState extends State<_NilaiView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        final profileId = user.profile?['id'] as int?;
        context.read<NilaiBloc>().add(
          NilaiLoadRequested(role: user.role ?? 'admin', profileId: profileId),
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
      appBar: AppBar(title: const Text('Nilai'), centerTitle: true),
      body: BlocBuilder<NilaiBloc, NilaiState>(
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
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Loaded View ───────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final NilaiLoaded state;
  final TextEditingController searchController;

  const _LoadedView({required this.state, required this.searchController});

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
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.lebarKontenMaks(context),
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  bloc.add(const NilaiRefreshRequested());
                },
                child: _buildContent(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final items = state.items;
    final hPad = Responsive.pagePadding(context).left;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (state.isRingkasanMode)
          SliverToBoxAdapter(child: _SummaryHeader(summary: state.summary)),
        if (state.isUjianMode)
          SliverToBoxAdapter(
            child: _UjianBanner(
              label: state.selectedUjian?.label ?? 'Ujian terpilih',
              subtitle: state.selectedUjian?.subtitle ?? '',
              jumlah: items.length,
            ),
          ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(message: _emptyMessage()),
          )
        else if (state.isRingkasanMode)
          _buildGroupedList(items)
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 4),
              child: Text(
                '${items.length} catatan nilai',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _NilaiSiswaTile(item: items[i]),
              childCount: items.length,
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildGroupedList(List<NilaiEntity> items) {
    final groups = _groupByMapel(items);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _MapelGroupCard(
          mapel: groups[i].key,
          items: groups[i].value,
          showSiswa: state.role != 'siswa',
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

/// Ambang warna nilai. Backend belum menyediakan kolom KKM pada tabel
/// `trx_nilai`/`trx_ujian`/`mst_mapel`, jadi ambang default dipakai.
Color _nilaiColor(double? nilai) {
  if (nilai == null) return AppColors.textSecondary;
  if (nilai >= 85) return AppColors.success;
  if (nilai >= 75) return AppColors.info;
  if (nilai >= 60) return AppColors.warning;
  return AppColors.error;
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
    final hPad = Responsive.pagePadding(context).left;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari nama siswa / mata pelajaran',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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
            horizontal: 12,
            vertical: 12,
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
    final hPad = Responsive.pagePadding(context).left;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: selectedId,
            isExpanded: true,
            hint: const Text('Pilih ujian', style: TextStyle(fontSize: 13)),
            icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
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
    final hPad = Responsive.pagePadding(context).left;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '$jumlah siswa dinilai',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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
    final hPad = Responsive.pagePadding(context).left;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: selected == null ? null : () => onChanged(null),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected == null
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardBg,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selected,
                isExpanded: true,
                isDense: false,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(
                  Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
                hint: const Text(
                  'Pilih semester',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                selectedItemBuilder: (context) => [
                  for (final o in options)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        o,
                        softWrap: true,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                    ),
                ],
                items: [
                  for (final o in options)
                    DropdownMenuItem<String?>(
                      value: o,
                      child: Text(
                        o,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
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
    final color = _nilaiColor(rata);
    final hPad = Responsive.pagePadding(context).left;
    final compact = Responsive.isCompact(context);
    final diameter = compact ? 64.0 : 76.0;

    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 12, hPad, 4),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: diameter,
                height: diameter,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(90), width: 2),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatNilai(rata),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        _predikat(rata),
                        maxLines: 1,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata Nilai',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.total} catatan nilai',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          // Tiga angka ringkasan — pakai Wrap supaya turun baris di layar
          // sangat sempit alih-alih meluber.
          LayoutBuilder(
            builder: (context, c) {
              const spacing = 8.0;
              final perBaris = c.maxWidth >= 260 ? 3 : 1;
              final lebarSel =
                  (c.maxWidth - spacing * (perBaris - 1)) / perBaris;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: lebarSel,
                    child: _MiniStat(
                      label: 'Mapel',
                      value: '${summary.jumlahMapel}',
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: lebarSel,
                    child: _MiniStat(
                      label: 'Tertinggi',
                      value: _formatNilai(summary.tertinggi),
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(
                    width: lebarSel,
                    child: _MiniStat(
                      label: 'Terendah',
                      value: _formatNilai(summary.terendah),
                      color: AppColors.error,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
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

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.pagePadding(context).left,
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _nilaiColor(rata),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mapel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _NilaiBadge(nilai: rata, label: 'Rata'),
              ],
            ),
            const SizedBox(height: 6),
            ...items.map((item) => _NilaiRow(item: item, showSiswa: showSiswa)),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                if (showSiswa && item.siswaNama != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.siswaNama!,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                if (jenis != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    jenis,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                if (semester != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    semester,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                if (tanggal != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    tanggal,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      height: 1.3,
                    ),
                  ),
                ],
                if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.keterangan!,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _NilaiBadge(nilai: item.nilai),
        ],
      ),
    );
  }
}

// ── Baris nilai untuk guru / admin ────────────────────────────────────────────

class _NilaiSiswaTile extends StatelessWidget {
  final NilaiEntity item;
  const _NilaiSiswaTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _nilaiColor(item.nilai);
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

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.pagePadding(context).left,
        vertical: 5,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.isCompact(context) ? 12 : 16,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(30),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _predikat(item.nilai),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.siswaNama ?? item.judul,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  if (item.siswaNis != null && item.siswaNis!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'NIS ${item.siswaNis}',
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    mapel,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (jenis != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      jenis,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (semester != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      semester,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (kelas != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      kelas,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _NilaiBadge(nilai: item.nilai),
          ],
        ),
      ),
    );
  }
}

// ── Badge nilai ───────────────────────────────────────────────────────────────

class _NilaiBadge extends StatelessWidget {
  final double? nilai;
  final String? label;

  const _NilaiBadge({required this.nilai, this.label});

  @override
  Widget build(BuildContext context) {
    final color = _nilaiColor(nilai);
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: color.withAlpha(200)),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatNilai(nilai),
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

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

// ── Empty View ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: Responsive.pagePadding(context) + const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
