import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wali/guardian_child_selector.dart';
import '../../domain/entities/ekstrakurikuler_entity.dart';
import '../../domain/entities/pendaftaran_ekskul_entity.dart';
import '../bloc/ekstrakurikuler_bloc.dart';
import '../widgets/ekstrakurikuler_widgets.dart';
import 'ekstrakurikuler_detail_page.dart';

/// Halaman utama modul Ekstrakurikuler.
///
/// Dua tab: **Semua Ekskul** (katalog) dan **Ekskul Saya** (keanggotaan siswa,
/// atau ekskul yang dibina untuk guru).
class EkstrakurikulerPage extends StatelessWidget {
  const EkstrakurikulerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EkstrakurikulerBloc>(),
      child: const _EkstrakurikulerView(),
    );
  }
}

class _EkstrakurikulerView extends StatefulWidget {
  const _EkstrakurikulerView();

  @override
  State<_EkstrakurikulerView> createState() => _EkstrakurikulerViewState();
}

class _EkstrakurikulerViewState extends State<_EkstrakurikulerView> {
  final TextEditingController _cariController = TextEditingController();
  List<GuardianChild> _children = const [];
  GuardianChild? _selectedChild;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final role = user.role ?? 'unknown';
      final profile = user.profile;
      final profileId = (profile?['id'] as num?)?.toInt();

      if (role == 'wali') {
        _loadChildren(user.profile?['id']);
        return;
      }
      _load(role, profileId, null, user);
    });
  }

  Future<void> _loadChildren(Object? waliId) async {
    final id = waliId is num ? waliId.toInt() : int.tryParse('$waliId');
    if (id == null) return;
    final children = await sl<GuardianChildService>().getChildren(id);
    if (!mounted || children.isEmpty) return;
    setState(() {
      _children = children;
      _selectedChild = children.first;
    });
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      _load('wali', children.first.id, null, auth.user);
    }
  }

  void _load(String role, int? siswaId, int? guruId, UserEntity user) {
    context.read<EkstrakurikulerBloc>().add(
      EkstrakurikulerLoadRequested(
        role: role,
        siswaId: siswaId,
        guruId: guruId,
        canManagePendaftaran: user.hasPermission(
          'ekstrakurikuler.pendaftaran.manage',
        ),
        canViewPendaftaran: user.hasPermission(
          'ekstrakurikuler.pendaftaran.view',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  void _bukaDetail(
    BuildContext context,
    EkstrakurikulerLoaded state,
    EkstrakurikulerEntity ekskul,
  ) {
    final bloc = context.read<EkstrakurikulerBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: EkstrakurikulerDetailPage(
            ekstrakurikulerId: ekskul.id,
            namaAwal: ekskul.nama,
            // Null untuk guru/admin; wali memakainya hanya untuk `check-status`.
            siswaId: state.siswaId,
            canViewPendaftaran: state.canViewPendaftaran,
            bolehMendaftar: state.bolehMendaftar,
            sudahTerdaftarDariDaftar: state.sudahTerdaftar(ekskul.id),
          ),
        ),
      ),
    );
  }

  Future<void> _konfirmasiKeluar(
    BuildContext context,
    PendaftaranEkskulEntity pendaftaran,
  ) async {
    final bloc = context.read<EkstrakurikulerBloc>();
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Ekskul'),
        content: Text(
          'Anda yakin ingin keluar dari "${pendaftaran.namaTampil}"? '
          'Status keanggotaan akan diubah menjadi "keluar".',
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

    if (setuju == true) {
      bloc.add(EkstrakurikulerKeluarRequested(pendaftaran.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final isWali = auth is AuthAuthenticated && auth.user.role == 'wali';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ekstrakurikuler'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              isWali && _selectedChild != null ? 112 : 48,
            ),
            child: Column(
              children: [
                if (isWali && _selectedChild != null)
                  GuardianChildSelector(
                    children: _children,
                    selectedId: _selectedChild!.id,
                    onChanged: (child) {
                      setState(() => _selectedChild = child);
                      _load('wali', child.id, null, auth.user);
                    },
                  ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Semua Ekskul'),
                    Tab(text: 'Ekskul Saya'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: BlocConsumer<EkstrakurikulerBloc, EkstrakurikulerState>(
          listenWhen: (_, current) =>
              current is EkstrakurikulerActionSuccess ||
              current is EkstrakurikulerActionFailure,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            if (state is EkstrakurikulerActionSuccess) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state is EkstrakurikulerActionFailure) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          buildWhen: (_, current) =>
              current is! EkstrakurikulerActionSuccess &&
              current is! EkstrakurikulerActionFailure,
          builder: (context, state) {
            if (state is EkstrakurikulerInitial ||
                state is EkstrakurikulerLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EkstrakurikulerError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<EkstrakurikulerBloc>().add(
                  const EkstrakurikulerRefreshRequested(),
                ),
              );
            }
            if (state is EkstrakurikulerLoaded) {
              return TabBarView(
                children: [
                  _TabSemua(
                    state: state,
                    cariController: _cariController,
                    onTapEkskul: (ekskul) =>
                        _bukaDetail(context, state, ekskul),
                  ),
                  _TabSaya(
                    state: state,
                    onTapEkskul: (ekskul) =>
                        _bukaDetail(context, state, ekskul),
                    onKeluar: (pendaftaran) =>
                        _konfirmasiKeluar(context, pendaftaran),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ── Tab: Semua Ekskul ────────────────────────────────────────────────────────

class _TabSemua extends StatelessWidget {
  final EkstrakurikulerLoaded state;
  final TextEditingController cariController;
  final ValueChanged<EkstrakurikulerEntity> onTapEkskul;

  const _TabSemua({
    required this.state,
    required this.cariController,
    required this.onTapEkskul,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<EkstrakurikulerBloc>();

    final pad = Responsive.pagePadding(context);

    return Column(
      children: [
        Container(
          color: AppColors.cardBg,
          padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 10),
          child: Column(
            children: [
              TextField(
                controller: cariController,
                onChanged: (value) =>
                    bloc.add(EkstrakurikulerSearchChanged(value)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cari nama, kode, pembina, atau hari',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: state.search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            cariController.clear();
                            bloc.add(const EkstrakurikulerSearchChanged(''));
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _SumberChip(
                    label: 'Aktif',
                    sumber: EkskulSumber.aktif,
                    selected: state.sumber == EkskulSumber.aktif,
                  ),
                  const SizedBox(width: 8),
                  _SumberChip(
                    label: 'Semua Status',
                    sumber: EkskulSumber.semua,
                    selected: state.sumber == EkskulSumber.semua,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(const EkstrakurikulerRefreshRequested());
            },
            child: BatasLebarKonten(
              child: state.semua.isEmpty
                  ? _ScrollableEmpty(
                      message: state.search.isNotEmpty
                          ? 'Tidak ada ekskul yang cocok dengan pencarian'
                          : 'Belum ada ekstrakurikuler',
                      icon: Icons.sports_soccer,
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 6, bottom: 20),
                      itemCount: state.semua.length,
                      itemBuilder: (context, index) {
                        final ekskul = state.semua[index];
                        final terdaftar = state.sudahTerdaftar(ekskul.id);
                        return EkstrakurikulerCard(
                          ekskul: ekskul,
                          sudahTerdaftar: terdaftar,
                          onTap: () => onTapEkskul(ekskul),
                          onDaftar:
                              state.bisaDaftar(ekskul.id) && ekskul.isAktif
                              ? () => bloc.add(
                                  EkstrakurikulerDaftarRequested(ekskul.id),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SumberChip extends StatelessWidget {
  final String label;
  final EkskulSumber sumber;
  final bool selected;

  const _SumberChip({
    required this.label,
    required this.sumber,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<EkstrakurikulerBloc>().add(
          EkstrakurikulerSumberChanged(sumber),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab: Ekskul Saya ─────────────────────────────────────────────────────────

class _TabSaya extends StatelessWidget {
  final EkstrakurikulerLoaded state;
  final ValueChanged<EkstrakurikulerEntity> onTapEkskul;
  final ValueChanged<PendaftaranEkskulEntity> onKeluar;

  const _TabSaya({
    required this.state,
    required this.onTapEkskul,
    required this.onKeluar,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<EkstrakurikulerBloc>();

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const EkstrakurikulerRefreshRequested());
      },
      child: BatasLebarKonten(
        child: state.isGuruMode ? _kontenGuru() : _kontenSiswa(),
      ),
    );
  }

  // ── Guru: ekskul yang dibina ───────────────────────────────────────────────

  Widget _kontenGuru() {
    if (state.pesanTabSaya != null && state.dibina.isEmpty) {
      return _ScrollableEmpty(
        message: state.pesanTabSaya!,
        icon: Icons.info_outline,
      );
    }
    if (state.dibina.isEmpty) {
      return const _ScrollableEmpty(
        message: 'Anda belum ditetapkan sebagai pembina ekstrakurikuler',
        icon: Icons.supervisor_account_outlined,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 20),
      itemCount: state.dibina.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const CatatanBanner(
            message:
                'Daftar ekstrakurikuler yang Anda bina. Endpoint pembina hanya '
                'mengembalikan ekskul berstatus aktif.',
          );
        }
        final ekskul = state.dibina[index - 1];
        return EkstrakurikulerCard(
          ekskul: ekskul,
          onTap: () => onTapEkskul(ekskul),
        );
      },
    );
  }

  // ── Siswa / wali / admin: keanggotaan + riwayat ────────────────────────────

  Widget _kontenSiswa() {
    if (state.pesanTabSaya != null &&
        state.keanggotaan.isEmpty &&
        state.riwayat.isEmpty) {
      return _ScrollableEmpty(
        message: state.pesanTabSaya!,
        icon: Icons.info_outline,
      );
    }

    final aktif = state.keanggotaan;
    final riwayatKeluar = state.riwayatKeluar;
    final tampilkanSiswa = !state.isSiswaMode;

    final anak = <Widget>[];

    if (state.pesanTabSaya != null) {
      anak.add(
        CatatanBanner(
          message: state.pesanTabSaya!,
          icon: Icons.warning_amber_outlined,
          color: AppColors.warning,
        ),
      );
    }

    anak.add(const _SectionHeader(label: 'Keanggotaan Aktif'));
    if (aktif.isEmpty) {
      anak.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'Belum mengikuti ekstrakurikuler apa pun.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    } else {
      for (final item in aktif) {
        anak.add(
          KeanggotaanCard(
            pendaftaran: item,
            tampilkanSiswa: tampilkanSiswa,
            onKeluar: state.bolehKeluar ? () => onKeluar(item) : null,
          ),
        );
      }
    }

    if (riwayatKeluar.isNotEmpty) {
      anak.add(const _SectionHeader(label: 'Riwayat'));
      for (final item in riwayatKeluar) {
        anak.add(
          KeanggotaanCard(pendaftaran: item, tampilkanSiswa: tampilkanSiswa),
        );
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      children: anak,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Empty view yang tetap bisa di-scroll (agar RefreshIndicator jalan) ───────

class _ScrollableEmpty extends StatelessWidget {
  final String message;
  final IconData icon;

  const _ScrollableEmpty({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          // Tinggi aman & sadar keyboard, bukan rasio tinggi layar mentah.
          height: Responsive.tinggiSheet(context, rasio: 0.6),
          child: _EmptyView(message: message, icon: icon),
        ),
      ],
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
  final IconData icon;
  const _EmptyView({required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
