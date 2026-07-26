import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/materi_entity.dart';
import '../bloc/materi_bloc.dart';
import '../widgets/materi_widgets.dart';
import 'materi_detail_page.dart';

class MateriPage extends StatelessWidget {
  const MateriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MateriBloc>(),
      child: const _MateriView(),
    );
  }
}

class _MateriView extends StatefulWidget {
  const _MateriView();

  @override
  State<_MateriView> createState() => _MateriViewState();
}

class _MateriViewState extends State<_MateriView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final role = _normalizeRole(user.role);
      final profile = user.profile;
      final profileId = (profile?['id'] as num?)?.toInt();

      final kelasRaw = profile?['kelas'];
      final kelasId = kelasRaw is Map
          ? (kelasRaw['id'] as num?)?.toInt()
          : (profile?['mst_kelas_id'] as num?)?.toInt() ??
                (profile?['kelas_id'] as num?)?.toInt();

      // Profil guru dari `/auth/me` tidak memuat id guru-mapel; tetap dicoba
      // bila suatu saat backend menambahkannya.
      final guruMapelId =
          (profile?['mst_guru_mapel_id'] as num?)?.toInt() ??
          (profile?['guru_mapel_id'] as num?)?.toInt();

      context.read<MateriBloc>().add(
        MateriLoadRequested(
          role: role,
          siswaId: role == 'siswa' ? profileId : null,
          kelasId: kelasId,
          guruId: role == 'guru' ? profileId : null,
          guruMapelId: role == 'guru' ? guruMapelId : null,
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Kode role backend berbentuk 'SISWA'/'GURU'/'WALI_SISWA'/'ADMIN'.
  /// `wali` diperiksa lebih dulu karena `WALI_SISWA` memuat kata "siswa".
  String _normalizeRole(String? raw) {
    final r = (raw ?? '').toLowerCase();
    if (r.contains('wali')) return 'wali';
    if (r.contains('guru')) return 'guru';
    if (r.contains('siswa')) return 'siswa';
    return 'admin';
  }

  void _bukaDetail(BuildContext context, MateriLoaded state, MateriEntity m) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MateriDetailPage(
          materi: m,
          role: state.role,
          siswaId: state.siswaId,
          kelasId: state.kelasId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi Pembelajaran'),
        centerTitle: true,
      ),
      body: BlocBuilder<MateriBloc, MateriState>(
        builder: (context, state) {
          if (state is MateriInitial || state is MateriLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MateriError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<MateriBloc>().add(
                const MateriRefreshRequested(),
              ),
            );
          }
          if (state is MateriLoaded) {
            return Column(
              children: [
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      context.read<MateriBloc>().add(MateriSearchChanged(v)),
                ),
                if (state.opsiMapel.length > 1) _MapelFilterBar(state: state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<MateriBloc>().add(
                        const MateriRefreshRequested(),
                      );
                    },
                    child: state.items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.55,
                                child: _EmptyView(
                                  message: _pesanKosong(state),
                                ),
                              ),
                            ],
                          )
                        : _MateriList(
                            state: state,
                            onTap: (m) => _bukaDetail(context, state, m),
                          ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _pesanKosong(MateriLoaded state) {
    if (state.adaFilterAktif) return 'Tidak ada materi yang cocok';
    if (state.isGuruMode) return 'Belum ada materi yang Anda unggah';
    return 'Belum ada materi pembelajaran';
  }
}

// ── Daftar materi (datar / dikelompokkan per mapel) ──────────────────────────

class _MateriList extends StatelessWidget {
  final MateriLoaded state;
  final void Function(MateriEntity) onTap;

  const _MateriList({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final baris = <_Baris>[];

    if (state.populer.isNotEmpty && state.bolehLihatStatistik) {
      baris.add(const _Baris.populer());
    }

    if (state.dikelompokkan) {
      for (final g in state.groups) {
        baris.add(_Baris.grup(g.mapelLabel, g.total));
        for (final m in g.items) {
          baris.add(_Baris.item(m));
        }
      }
    } else {
      for (final m in state.items) {
        baris.add(_Baris.item(m));
      }
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: baris.length,
      itemBuilder: (context, index) {
        final b = baris[index];
        if (b.stripPopuler) return _PopulerStrip(state: state);
        final m = b.materi;
        if (m != null) {
          return MateriCard(
            materi: m,
            tampilkanStatus: state.bolehLihatStatistik,
            onTap: () => onTap(m),
          );
        }
        return MateriGroupHeader(label: b.judulGrup ?? '', total: b.totalGrup);
      },
    );
  }
}

/// Baris daftar: strip materi populer, header kelompok, atau kartu materi.
class _Baris {
  final MateriEntity? materi;
  final String? judulGrup;
  final int totalGrup;
  final bool stripPopuler;

  const _Baris.item(this.materi)
    : judulGrup = null,
      totalGrup = 0,
      stripPopuler = false;

  const _Baris.grup(this.judulGrup, this.totalGrup)
    : materi = null,
      stripPopuler = false;

  const _Baris.populer()
    : materi = null,
      judulGrup = null,
      totalGrup = 0,
      stripPopuler = true;
}

// ── Strip materi populer (guru & admin) ──────────────────────────────────────

class _PopulerStrip extends StatelessWidget {
  final MateriLoaded state;
  const _PopulerStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 16,
                color: AppColors.warning,
              ),
              SizedBox(width: 6),
              Text(
                'Materi Paling Sering Dibuka',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.populer.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final p = state.populer[index];
              return Container(
                width: 190,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.judulLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.totalAkses}x dibuka · ${formatDurasi(p.totalDurasiDetik)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Pencarian ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari judul, mapel, atau guru...',
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

// ── Filter mata pelajaran ────────────────────────────────────────────────────

class _MapelFilterBar extends StatelessWidget {
  final MateriLoaded state;
  const _MapelFilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final opsi = <String?>[null, ...state.opsiMapel];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: opsi.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final nilai = opsi[index];
            final terpilih = state.mapelTerpilih == nilai;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.read<MateriBloc>().add(
                MateriMapelFilterChanged(nilai),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: terpilih ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: terpilih ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  nilai ?? 'Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: terpilih ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
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
            Icons.menu_book_outlined,
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
    );
  }
}
