import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/forum_entity.dart';
import '../bloc/forum_bloc.dart';
import '../widgets/forum_visuals.dart';
import '../widgets/forum_widgets.dart';
import 'forum_detail_page.dart';
import 'forum_form_page.dart';

/// Halaman utama Forum Diskusi.
///
/// Backend (`trx_forum`) TIDAK punya konsep balasan/threading — tidak ada
/// `parent_id`, tidak ada tabel balasan, dan tidak ada endpoint balasan.
/// Karena itu halaman ini adalah daftar post datar, bukan daftar thread.
class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ForumBloc>(),
      child: const _ForumView(),
    );
  }
}

class _ForumView extends StatefulWidget {
  const _ForumView();

  @override
  State<_ForumView> createState() => _ForumViewState();
}

class _ForumViewState extends State<_ForumView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// Disimpan lokal supaya chip tidak "melompat" ke Semua saat state
  /// sementara berubah jadi `ForumLoading`.
  int? _tipeTerpilih;

  /// Permission dibaca sekali dari `AuthBloc`; tidak ikut berubah mengikuti
  /// state transien `ForumBloc`, sehingga FAB tidak berkedip.
  bool _bolehBuat = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final profile = user.profile;

      // `sekolah_id` tidak dikirim `UserResource`; disertakan sebagai petunjuk
      // saja bila suatu saat tersedia di profil. Bila null, `ForumBloc`
      // menyimpulkannya dari post yang dimuat.
      final sekolahIdHint =
          (profile?['sekolah_id'] as num?)?.toInt() ??
          (profile?['mst_sekolah_id'] as num?)?.toInt();

      setState(() => _bolehBuat = user.hasPermission('forum.create'));

      context.read<ForumBloc>().add(
        ForumLoadRequested(
          userId: user.id,
          canCreate: user.hasPermission('forum.create'),
          canUpdate: user.hasPermission('forum.update'),
          canDelete: user.hasPermission('forum.delete'),
          sekolahIdHint: sekolahIdHint,
        ),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final posisi = _scrollController.position;
    if (posisi.pixels >= posisi.maxScrollExtent - 240) {
      context.read<ForumBloc>().add(const ForumLoadMoreRequested());
    }
  }

  /// Pencarian dikirim ke backend (`ForumService::applyBaseFilters` menerapkan
  /// `search` pada kolom `judul` dan `konten`), dengan jeda ketik 450 ms.
  void _onSearchChanged(String nilai) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<ForumBloc>().add(ForumSearchChanged(nilai));
    });
  }

  Future<void> _bukaDetail(BuildContext context, ForumEntity post) {
    final bloc = context.read<ForumBloc>();
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ForumDetailPage(forumId: post.id, postAwal: post),
        ),
      ),
    );
  }

  Future<void> _buatTopik(BuildContext context) async {
    final bloc = context.read<ForumBloc>();
    final hasil = await Navigator.of(context).push<ForumFormResult>(
      MaterialPageRoute(builder: (_) => const ForumFormPage()),
    );
    if (hasil == null) return;

    bloc.add(
      ForumCreateRequested(
        judul: hasil.judul,
        konten: hasil.konten,
        tipe: hasil.tipe,
        isAnonymous: hasil.isAnonymous,
      ),
    );
  }

  Future<void> _ubahTopik(BuildContext context, ForumEntity post) async {
    final bloc = context.read<ForumBloc>();
    final hasil = await Navigator.of(context).push<ForumFormResult>(
      MaterialPageRoute(builder: (_) => ForumFormPage(awal: post)),
    );
    if (hasil == null) return;

    bloc.add(
      ForumUpdateRequested(
        id: post.id,
        judul: hasil.judul,
        konten: hasil.konten,
        tipe: hasil.tipe,
        isAnonymous: hasil.isAnonymous,
      ),
    );
  }

  Future<void> _hapusTopik(BuildContext context, ForumEntity post) async {
    final bloc = context.read<ForumBloc>();
    final setuju = await konfirmasiHapusForum(context, post.judul);
    if (!setuju) return;
    bloc.add(ForumDeleteRequested(post.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forum Diskusi'), centerTitle: true),
      // FAB hanya tampil bila user punya permission `forum.create`.
      floatingActionButton: !_bolehBuat
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _buatTopik(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Topik Baru'),
            ),
      body: BlocConsumer<ForumBloc, ForumState>(
        listenWhen: (_, current) =>
            current is ForumActionSuccess || current is ForumActionFailure,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is ForumActionSuccess) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
          } else if (state is ForumActionFailure) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        },
        buildWhen: (_, current) =>
            current is! ForumActionSuccess && current is! ForumActionFailure,
        builder: (context, state) {
          if (state is ForumInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ForumError) {
            return ForumErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<ForumBloc>().add(const ForumRefreshRequested()),
            );
          }

          return Column(
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _debounce?.cancel();
                  context.read<ForumBloc>().add(const ForumSearchChanged(''));
                },
              ),
              _TipeFilterBar(
                tipeAktif: _tipeTerpilih,
                onPilih: (tipe) {
                  setState(() => _tipeTerpilih = tipe);
                  context.read<ForumBloc>().add(ForumTipeFilterChanged(tipe));
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                // Sengaja pakai type-check, bukan cast: rebuild yang dipicu
                // parent (`setState`) bisa membawa state transien
                // `ForumActionSuccess`/`ForumActionFailure` ke builder ini.
                child: state is ForumLoaded
                    ? _Daftar(
                        state: state,
                        scrollController: _scrollController,
                        onTap: (post) => _bukaDetail(context, post),
                        onUbah: (post) => _ubahTopik(context, post),
                        onHapus: (post) => _hapusTopik(context, post),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Daftar ──────────────────────────────────────────────────────────────────

class _Daftar extends StatelessWidget {
  final ForumLoaded state;
  final ScrollController scrollController;
  final ValueChanged<ForumEntity> onTap;
  final ValueChanged<ForumEntity> onUbah;
  final ValueChanged<ForumEntity> onHapus;

  const _Daftar({
    required this.state,
    required this.scrollController,
    required this.onTap,
    required this.onUbah,
    required this.onHapus,
  });

  String get _pesanKosong {
    if (state.search.isNotEmpty) {
      return 'Tidak ada topik yang cocok dengan "${state.search}"';
    }
    if (state.tipe != null) {
      return 'Belum ada topik bertipe ${forumTipeOf(state.tipe).label}';
    }
    return 'Belum ada topik diskusi';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ForumBloc>().add(const ForumRefreshRequested());
      },
      // Lebar daftar dibatasi di tablet supaya kartu tidak melebar.
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.lebarKontenMaks(context),
          ),
          child: state.items.isEmpty
              ? ListView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      // Tinggi aman (sadar keyboard & area sistem).
                      height: Responsive.tinggiSheet(context, rasio: 0.55),
                      child: ForumEmptyView(message: _pesanKosong),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 6, bottom: 88),
                  itemCount: state.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == state.items.length) {
                      return _Footer(state: state);
                    }

                    final post = state.items[index];
                    return ForumCard(
                      post: post,
                      bolehUbah: state.bolehUbah(post),
                      bolehHapus: state.bolehHapus(post),
                      milikSaya: post.milikUser(state.userId),
                      onTap: () => onTap(post),
                      onAksi: (aksi) {
                        if (aksi == ForumAksi.ubah) {
                          onUbah(post);
                        } else {
                          onHapus(post);
                        }
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ForumLoaded state;
  const _Footer({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (state.hasMore) return const SizedBox(height: 20);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          state.total != null
              ? '${state.total} topik'
              : '${state.items.length} topik',
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ),
    );
  }
}

// ── Pencarian ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari judul atau isi topik…',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Bersihkan',
                    onPressed: onClear,
                  ),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

// ── Filter tipe ─────────────────────────────────────────────────────────────

class _TipeFilterBar extends StatelessWidget {
  final int? tipeAktif;
  final ValueChanged<int?> onPilih;

  const _TipeFilterBar({required this.tipeAktif, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);
    final skala = MediaQuery.textScalerOf(context).scale(1);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, 10),
      child: SizedBox(
        // Tinggi chip ikut skala font sistem agar label tidak terpotong.
        height: 32.0 * (skala > 1 ? skala : 1.0),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _Chip(
              label: 'Semua',
              terpilih: tipeAktif == null,
              warna: AppColors.primary,
              onTap: () => onPilih(null),
            ),
            for (final t in forumTipeOptions) ...[
              const SizedBox(width: 8),
              _Chip(
                label: t.label,
                icon: t.icon,
                terpilih: tipeAktif == t.nilai,
                warna: t.color,
                onTap: () => onPilih(t.nilai),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool terpilih;
  final Color warna;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    this.icon,
    required this.terpilih,
    required this.warna,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: terpilih ? warna : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: terpilih ? warna : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: terpilih ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            // Tanpa Flexible: chip berada di dalam ListView horizontal
            // (lebar tak terbatas), jadi anak flex tidak boleh dipakai.
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: terpilih ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
