import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/ranking_entity.dart';
import '../../domain/entities/ujian_entity.dart';
import '../bloc/ujian_bloc.dart';
import 'ujian_nilai_page.dart';

/// Halaman utama modul Ujian: tab **Ujian** (daftar ujian per kelas) dan
/// tab **Ranking** (papan peringkat kelas).
class UjianPage extends StatelessWidget {
  const UjianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UjianBloc>(),
      child: const _UjianView(),
    );
  }
}

class _UjianView extends StatefulWidget {
  const _UjianView();

  @override
  State<_UjianView> createState() => _UjianViewState();
}

class _UjianViewState extends State<_UjianView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dispatchLoad();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Kode role backend berbentuk 'SISWA'/'GURU'/'WALI_SISWA'/'ADMIN'.
  /// 'WALI_SISWA' mengandung substring 'siswa' → cek wali dulu; sedangkan
  /// 'WALI_KELAS' adalah guru wali kelas → masuk mode guru.
  String _normalizeRole(String? raw) {
    final r = (raw ?? '').toLowerCase();
    if (r.contains('wali') && !r.contains('kelas')) return 'wali';
    if (r.contains('guru') || r.contains('wali_kelas')) return 'guru';
    if (r.contains('siswa')) return 'siswa';
    return 'admin';
  }

  void _dispatchLoad() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    final role = _normalizeRole(user.role);
    final profile = user.profile;
    final profileId = (profile?['id'] as num?)?.toInt();

    // Siswa: kelas dari `profile['kelas']['id']` (fallback bentuk lain).
    int? kelasId;
    String? kelasNama;
    if (role == 'siswa') {
      final kelas = profile?['kelas'];
      if (kelas is Map) {
        kelasId = (kelas['id'] as num?)?.toInt();
        kelasNama = kelas['nama_kelas'] as String?;
      }
      kelasId ??= (profile?['mst_kelas_id'] as num?)?.toInt();
      kelasId ??= (profile?['kelas_id'] as num?)?.toInt();
    }

    context.read<UjianBloc>().add(
      UjianLoadRequested(
        role: role,
        profileId: profileId,
        siswaId: role == 'siswa' ? profileId : null,
        kelasId: kelasId,
        kelasNama: kelasNama,
        canViewUjian: user.hasPermission('ujian.view'),
        canViewRanking: user.hasPermission('ranking.view'),
        canGenerate: user.hasPermission('ranking.generate'),
        canExport: user.hasPermission('ranking.export'),
      ),
    );
  }

  Future<void> _bukaBerkas(BuildContext context, String path) async {
    final result = await OpenFilex.open(path);
    if (!context.mounted) return;
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berkas ranking tersimpan di:\n$path\n'
            'Tidak ada aplikasi yang bisa membuka berkas .xlsx di perangkat ini.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  /// Form parameter generate/export: id mst_semester + id mst_tahun_ajaran.
  ///
  /// Tidak ada endpoint daftar semester/tahun ajaran yang bisa diakses
  /// role mobile non-sysadmin (`semester.view` hanya milik admin), jadi
  /// nilainya diisi manual dengan prefill dari data yang sudah termuat
  /// (baris ranking / daftar ujian / tahun ajaran kelas terpilih).
  Future<void> _mintaParameter(
    BuildContext context,
    UjianLoaded state, {
    required String judul,
    required String labelTombol,
    required void Function(int semesterId, int tahunAjaranId) onSubmit,
  }) async {
    final semesterController = TextEditingController(
      text: state.prefillSemesterId?.toString() ?? '',
    );
    final tahunController = TextEditingController(
      text: state.prefillTahunAjaranId?.toString() ?? '',
    );

    final hasil = await showModalBottomSheet<(int, int)>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              judul,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kelas: ${state.kelasNama ?? state.kelasId ?? '-'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: semesterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID Semester (mst_semester)',
                helperText: 'Terisi otomatis dari data ranking/ujian yang ada',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tahunController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID Tahun Ajaran (mst_tahun_ajaran)',
                helperText: 'Terisi otomatis dari tahun ajaran kelas',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final semesterId = int.tryParse(
                  semesterController.text.trim(),
                );
                final tahunId = int.tryParse(tahunController.text.trim());
                if (semesterId == null || tahunId == null) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'ID semester dan tahun ajaran wajib berupa angka',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.of(sheetContext).pop((semesterId, tahunId));
              },
              child: Text(labelTombol),
            ),
          ],
        ),
      ),
    );

    semesterController.dispose();
    tahunController.dispose();

    if (hasil != null) onSubmit(hasil.$1, hasil.$2);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UjianBloc, UjianState>(
      listenWhen: (_, current) =>
          current is UjianActionSuccess || current is UjianActionFailure,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state is UjianActionSuccess) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          final path = state.filePath;
          if (path != null) _bukaBerkas(context, path);
        } else if (state is UjianActionFailure) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      buildWhen: (_, current) =>
          current is! UjianActionSuccess && current is! UjianActionFailure,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ujian & Ranking'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Ujian'),
                Tab(text: 'Ranking'),
              ],
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UjianState state) {
    if (state is UjianInitial || state is UjianLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is UjianError) {
      return _ErrorView(message: state.message, onRetry: _dispatchLoad);
    }

    if (state is! UjianLoaded) return const SizedBox.shrink();

    // Tanpa izin sama sekali (mis. role wali): satu tampilan akses ditolak.
    if (!state.canViewUjian && !state.canViewRanking) {
      return const _NoAccessView(
        message:
            'Akun Anda tidak memiliki izin ujian.view maupun ranking.view. '
            'Untuk orang tua/wali, nilai anak dapat dilihat melalui menu '
            'Nilai dan Rapor.',
      );
    }

    // Guru yang bukan wali kelas: backend hanya mengizinkan akses ujian/
    // ranking untuk kelas dengan wali_guru_id = guru ybs (canAccessKelasId).
    if (state.pakaiPemilihKelas && state.kelasOptions.isEmpty) {
      return _NoAccessView(
        message: state.role == 'guru'
            ? 'Anda tidak terdaftar sebagai wali kelas. Backend hanya '
                  'mengizinkan guru melihat ujian & ranking kelas yang '
                  'diampunya sebagai wali kelas.'
            : 'Belum ada data kelas yang dapat dipilih.',
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            if (state.pakaiPemilihKelas) _KelasSelector(state: state),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UjianTab(state: state),
                  _RankingTab(
                    state: state,
                    onGenerate: () => _mintaParameter(
                      context,
                      state,
                      judul: 'Generate Ranking',
                      labelTombol: 'Generate',
                      onSubmit: (semesterId, tahunId) =>
                          context.read<UjianBloc>().add(
                            UjianGenerateRequested(
                              semesterId: semesterId,
                              tahunAjaranId: tahunId,
                            ),
                          ),
                    ),
                    onExport: () => _mintaParameter(
                      context,
                      state,
                      judul: 'Export Ranking (xlsx)',
                      labelTombol: 'Unduh',
                      onSubmit: (semesterId, tahunId) =>
                          context.read<UjianBloc>().add(
                            UjianExportRequested(
                              semesterId: semesterId,
                              tahunAjaranId: tahunId,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (state.aksiSedangDiproses)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
      ],
    );
  }
}

// ── Pemilih kelas (guru/admin) ───────────────────────────────────────────────

class _KelasSelector extends StatelessWidget {
  final UjianLoaded state;
  const _KelasSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: DropdownButtonFormField<int>(
        initialValue: state.kelasTerpilih?.id,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Kelas',
          prefixIcon: Icon(Icons.school_outlined, color: AppColors.primary),
          isDense: true,
        ),
        hint: const Text('Pilih kelas'),
        items: [
          for (final kelas in state.kelasOptions)
            DropdownMenuItem<int>(
              value: kelas.id,
              child: Text(
                kelas.tahunAjaranNama == null
                    ? kelas.namaKelas
                    : '${kelas.namaKelas} · ${kelas.tahunAjaranNama}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
        onChanged: state.aksiSedangDiproses
            ? null
            : (value) {
                if (value != null && value != state.kelasId) {
                  context.read<UjianBloc>().add(UjianKelasChanged(value));
                }
              },
      ),
    );
  }
}

// ── Tab Ujian ────────────────────────────────────────────────────────────────

class _UjianTab extends StatelessWidget {
  final UjianLoaded state;
  const _UjianTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.canViewUjian) {
      return const _NoAccessView(
        message: 'Akun Anda tidak memiliki izin melihat ujian (ujian.view).',
      );
    }

    if (state.kelasId == null) {
      return const _PilihKelasPrompt();
    }

    final bloc = context.read<UjianBloc>();

    if (state.ujianError != null) {
      return _ErrorView(
        message: state.ujianError!,
        onRetry: () => bloc.add(const UjianRefreshRequested()),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const UjianRefreshRequested()),
      child: state.ujianItems.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const _EmptyView(
                    icon: Icons.assignment_outlined,
                    message: 'Belum ada ujian untuk kelas ini',
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: state.ujianItems.length,
              itemBuilder: (context, index) {
                final ujian = state.ujianItems[index];
                return _UjianCard(
                  ujian: ujian,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => UjianNilaiPage(
                        ujianId: ujian.id,
                        judulAwal: ujian.nama,
                        siswaId: state.siswaId,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _UjianCard extends StatelessWidget {
  final UjianEntity ujian;
  final VoidCallback onTap;

  const _UjianCard({required this.ujian, required this.onTap});

  static const _months = [
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

  String _tanggalLabel() {
    final d = ujian.tanggalDate;
    if (d == null) return ujian.tanggal ?? '-';
    return '${d.day} ${_months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final semesterInfo = [
      if (ujian.semesterNama != null) ujian.semesterNama!,
      if (ujian.tahunAjaran != null) ujian.tahunAjaran!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(25),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ujian.nama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (ujian.mapelNama != null) ujian.mapelNama!,
                        _tanggalLabel(),
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (semesterInfo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        semesterInfo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (ujian.jenisLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.info.withAlpha(90),
                        ),
                      ),
                      child: Text(
                        ujian.jenisLabel!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab Ranking ──────────────────────────────────────────────────────────────

class _RankingTab extends StatelessWidget {
  final UjianLoaded state;
  final VoidCallback onGenerate;
  final VoidCallback onExport;

  const _RankingTab({
    required this.state,
    required this.onGenerate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.canViewRanking) {
      return const _NoAccessView(
        message:
            'Akun Anda tidak memiliki izin melihat ranking (ranking.view).',
      );
    }

    if (state.kelasId == null) {
      return const _PilihKelasPrompt();
    }

    final bloc = context.read<UjianBloc>();

    if (state.rankingError != null) {
      return _ErrorView(
        message: state.rankingError!,
        onRetry: () => bloc.add(const UjianRefreshRequested()),
      );
    }

    final pertama = state.rankingItems.firstOrNull;
    final periodeInfo = pertama == null
        ? null
        : [
            if (pertama.semesterNama != null)
              'Semester ${pertama.semesterNama}',
            if (pertama.tahunAjaran != null) pertama.tahunAjaran!,
          ].join(' · ');

    return Column(
      children: [
        if (state.canGenerate || state.canExport)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (state.canGenerate)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.aksiSedangDiproses ? null : onGenerate,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text(
                        'Generate Ranking',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                      ),
                    ),
                  ),
                if (state.canGenerate && state.canExport)
                  const SizedBox(width: 8),
                if (state.canExport)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.aksiSedangDiproses ? null : onExport,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text(
                        'Export xlsx',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => bloc.add(const UjianRefreshRequested()),
            child: state.rankingItems.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _EmptyView(
                          icon: Icons.emoji_events_outlined,
                          message: state.canGenerate
                              ? 'Belum ada ranking untuk kelas ini.\n'
                                    'Gunakan tombol "Generate Ranking" untuk '
                                    'menyusun peringkat dari rata-rata rapor.'
                              : 'Belum ada ranking untuk kelas ini',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount:
                        state.rankingItems.length +
                        (periodeInfo == null || periodeInfo.isEmpty ? 0 : 1),
                    itemBuilder: (context, index) {
                      final punyaHeader =
                          periodeInfo != null && periodeInfo.isNotEmpty;
                      if (punyaHeader && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                          child: Text(
                            periodeInfo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      final item = state
                          .rankingItems[punyaHeader ? index - 1 : index];
                      return _RankingRow(
                        item: item,
                        milikSaya:
                            state.siswaId != null &&
                            item.siswaId == state.siswaId,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final RankingEntity item;
  final bool milikSaya;

  const _RankingRow({required this.item, required this.milikSaya});

  /// Warna sorotan 3 besar: emas, perak, perunggu.
  Color? _medalColor() {
    switch (item.peringkat) {
      case 1:
        return const Color(0xFFF9A825);
      case 2:
        return const Color(0xFF90A4AE);
      case 3:
        return const Color(0xFF8D6E63);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final medal = _medalColor();
    final rankLabel = item.peringkat?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: milikSaya
            ? AppColors.primary.withAlpha(18)
            : medal != null
            ? medal.withAlpha(14)
            : AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: milikSaya
              ? AppColors.primary
              : medal?.withAlpha(120) ?? AppColors.divider,
          width: milikSaya ? 1.4 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Nomor urut / medali
          SizedBox(
            width: 38,
            child: medal != null
                ? Column(
                    children: [
                      Icon(Icons.emoji_events, color: medal, size: 22),
                      Text(
                        rankLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: medal,
                        ),
                      ),
                    ],
                  )
                : CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.surface,
                    child: Text(
                      rankLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.siswaNama ?? 'Siswa #${item.siswaId ?? '-'}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: milikSaya || medal != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (milikSaya) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Anda',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.nis != null)
                  Text(
                    'NIS ${item.nis}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.rataRata == null
                    ? '-'
                    : item.rataRata!.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: medal ?? AppColors.primary,
                ),
              ),
              const Text(
                'rata-rata',
                style: TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Prompt pilih kelas (admin sebelum memilih) ───────────────────────────────

class _PilihKelasPrompt extends StatelessWidget {
  const _PilihKelasPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'Pilih kelas terlebih dahulu untuk melihat '
              'daftar ujian dan ranking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tanpa akses ──────────────────────────────────────────────────────────────

class _NoAccessView extends StatelessWidget {
  final String message;
  const _NoAccessView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 42,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Akses Ditolak',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 44),
              ),
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
  final IconData icon;
  const _EmptyView({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
