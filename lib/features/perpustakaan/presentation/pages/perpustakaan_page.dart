import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/peminjaman_buku_entity.dart';
import '../bloc/perpustakaan_bloc.dart';
import '../widgets/perpustakaan_widgets.dart';
import 'buku_detail_page.dart';

/// Halaman utama modul Perpustakaan: tab **Katalog** dan tab **Peminjaman**.
class PerpustakaanPage extends StatelessWidget {
  const PerpustakaanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PerpustakaanBloc>(),
      child: const _PerpustakaanView(),
    );
  }
}

class _PerpustakaanView extends StatefulWidget {
  const _PerpustakaanView();

  @override
  State<_PerpustakaanView> createState() => _PerpustakaanViewState();
}

class _PerpustakaanViewState extends State<_PerpustakaanView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final role = _normalizeRole(user.role);
      final profileId = (user.profile?['id'] as num?)?.toInt();

      context.read<PerpustakaanBloc>().add(
        PerpustakaanLoadRequested(
          role: role,
          // Untuk role wali `profile` tidak memuat id siswa, jadi siswaId
          // sengaja dibiarkan null → bloc memakai endpoint index yang sudah
          // difilter backend per sesi.
          siswaId: role == 'siswa' ? profileId : null,
          canCreate: user.hasPermission('peminjaman.create'),
          canPengembalian: user.hasPermission('peminjaman.pengembalian'),
          // Sengaja digate pada `peminjaman.update` (level petugas), BUKAN
          // `peminjaman.view` — siswa juga memiliki `peminjaman.view`
          // (RbacSeeder), sedangkan endpoint `/buku/{id}/peminjaman` tidak
          // difilter per sesi dan memuat nama + NIS peminjam lain.
          canLihatRiwayat: user.hasPermission('peminjaman.update'),
        ),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Kode role backend berbentuk 'SISWA'/'GURU'/'WALI_SISWA'/'ADMIN'.
  /// Cek `wali` DULU karena 'WALI_SISWA' mengandung substring 'siswa'.
  String _normalizeRole(String? raw) {
    final r = (raw ?? '').toLowerCase();
    if (r.contains('wali')) return 'wali';
    if (r.contains('guru')) return 'guru';
    if (r.contains('siswa')) return 'siswa';
    return 'admin';
  }

  void _bukaDetail(BuildContext context, PerpustakaanLoaded state, int index) {
    final buku = state.buku[index];
    final bloc = context.read<PerpustakaanBloc>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: BukuDetailPage(
            bukuId: buku.id,
            judulAwal: buku.judul,
            canLihatRiwayat: state.canLihatRiwayat,
            canPinjam: state.canCreate,
            defaultSiswaId: state.siswaId,
            kunciSiswa: state.isSiswaMode && state.siswaId != null,
          ),
        ),
      ),
    );
  }

  Future<void> _konfirmasiPengembalian(
    BuildContext context,
    PeminjamanBukuEntity item,
  ) async {
    final bloc = context.read<PerpustakaanBloc>();
    final judul = item.bukuJudul ?? 'buku ini';

    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Proses Pengembalian'),
        content: Text(
          'Tandai "$judul" sebagai sudah dikembalikan? '
          'Stok buku akan bertambah satu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Proses'),
          ),
        ],
      ),
    );

    if (setuju == true) {
      bloc.add(PerpustakaanPengembalianRequested(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PerpustakaanBloc, PerpustakaanState>(
      listenWhen: (_, current) =>
          current is PerpustakaanActionSuccess ||
          current is PerpustakaanActionFailure,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state is PerpustakaanActionSuccess) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is PerpustakaanActionFailure) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      buildWhen: (_, current) =>
          current is! PerpustakaanActionSuccess &&
          current is! PerpustakaanActionFailure,
      builder: (context, state) {
        final labelTab = state is PerpustakaanLoaded
            ? state.labelTabPeminjaman
            : 'Peminjaman';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Perpustakaan'),
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
              tabs: [
                const Tab(text: 'Katalog'),
                Tab(text: labelTab),
              ],
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PerpustakaanState state) {
    if (state is PerpustakaanInitial || state is PerpustakaanLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PerpustakaanError) {
      return PerpustakaanErrorView(
        message: state.message,
        onRetry: () => context.read<PerpustakaanBloc>().add(
          const PerpustakaanRefreshRequested(),
        ),
      );
    }

    if (state is! PerpustakaanLoaded) return const SizedBox.shrink();

    return Stack(
      children: [
        TabBarView(
          controller: _tabController,
          children: [
            _KatalogTab(
              state: state,
              searchController: _searchController,
              onTapBuku: (index) => _bukaDetail(context, state, index),
            ),
            _PeminjamanTab(
              state: state,
              onPengembalian: (item) => _konfirmasiPengembalian(context, item),
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

// ── Tab Katalog ──────────────────────────────────────────────────────────────

class _KatalogTab extends StatelessWidget {
  final PerpustakaanLoaded state;
  final TextEditingController searchController;
  final ValueChanged<int> onTapBuku;

  const _KatalogTab({
    required this.state,
    required this.searchController,
    required this.onTapBuku,
  });

  String _pesanKosong() {
    if (state.bukuError != null) return state.bukuError!;
    if (state.searchQuery.trim().isNotEmpty) {
      return 'Tidak ada buku yang cocok dengan "${state.searchQuery.trim()}"';
    }
    if (state.hanyaTersedia) {
      return 'Tidak ada buku yang tersedia untuk dipinjam saat ini';
    }
    return 'Belum ada buku di katalog perpustakaan';
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PerpustakaanBloc>();

    if (state.bukuError != null && state.buku.isEmpty) {
      return PerpustakaanErrorView(
        message: state.bukuError!,
        onRetry: () => bloc.add(
          const PerpustakaanRefreshRequested(PerpustakaanScope.katalog),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: (value) =>
                    bloc.add(PerpustakaanSearchChanged(value)),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari judul atau pengarang',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: state.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            searchController.clear();
                            bloc.add(const PerpustakaanSearchChanged(''));
                          },
                        ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Hanya yang tersedia'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: state.hanyaTersedia
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    selected: state.hanyaTersedia,
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: state.hanyaTersedia
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    side: BorderSide(
                      color: state.hanyaTersedia
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                    onSelected: (value) =>
                        bloc.add(PerpustakaanHanyaTersediaChanged(value)),
                  ),
                  const Spacer(),
                  Text(
                    state.buku.length == state.totalBuku
                        ? '${state.totalBuku} buku'
                        : '${state.buku.length} dari ${state.totalBuku} buku',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(
                const PerpustakaanRefreshRequested(PerpustakaanScope.katalog),
              );
            },
            child: state.buku.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: PerpustakaanEmptyView(message: _pesanKosong()),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 6, bottom: 24),
                    itemCount: state.buku.length,
                    itemBuilder: (context, index) => BukuCard(
                      buku: state.buku[index],
                      onTap: () => onTapBuku(index),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Tab Peminjaman ───────────────────────────────────────────────────────────

class _PeminjamanTab extends StatelessWidget {
  final PerpustakaanLoaded state;
  final ValueChanged<PeminjamanBukuEntity> onPengembalian;

  const _PeminjamanTab({required this.state, required this.onPengembalian});

  String _pesanKosong() {
    if (state.isSiswaMode) return 'Anda belum meminjam buku apa pun';
    if (state.isWaliMode) {
      return 'Belum ada peminjaman buku untuk anak Anda';
    }
    if (state.isGuruMode) return 'Belum ada peminjaman buku dari siswa Anda';
    return 'Belum ada data peminjaman buku';
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PerpustakaanBloc>();

    if (state.peminjamanError != null && state.peminjaman.isEmpty) {
      return PerpustakaanErrorView(
        message: state.peminjamanError!,
        onRetry: () => bloc.add(
          const PerpustakaanRefreshRequested(PerpustakaanScope.peminjaman),
        ),
      );
    }

    return Column(
      children: [
        if (state.peminjaman.isNotEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                PerpustakaanBadge(
                  label: '${state.jumlahAktif} sedang dipinjam',
                  color: AppColors.info,
                  icon: Icons.menu_book_outlined,
                ),
                const SizedBox(width: 8),
                if (state.jumlahTerlambat > 0)
                  PerpustakaanBadge(
                    label: '${state.jumlahTerlambat} terlambat',
                    color: AppColors.error,
                    icon: Icons.warning_amber_rounded,
                  ),
                const Spacer(),
                Text(
                  '${state.peminjaman.length} data',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(
                const PerpustakaanRefreshRequested(
                  PerpustakaanScope.peminjaman,
                ),
              );
            },
            child: state.peminjaman.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: PerpustakaanEmptyView(
                          message: _pesanKosong(),
                          icon: Icons.import_contacts_outlined,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 6, bottom: 24),
                    itemCount: state.peminjaman.length,
                    itemBuilder: (context, index) {
                      final item = state.peminjaman[index];
                      return PeminjamanCard(
                        item: item,
                        terlambat: state.terlambat(item),
                        tampilkanSiswa: !state.isSiswaMode,
                        canPengembalian: state.canPengembalian,
                        onPengembalian: state.aksiSedangDiproses
                            ? null
                            : () => onPengembalian(item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
