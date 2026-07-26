import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/bk_kasus_entity.dart';
import '../bloc/bk_bloc.dart';
import '../widgets/bk_visuals.dart';
import 'bk_detail_page.dart';
import 'bk_kasus_form_page.dart';

/// Halaman utama modul Bimbingan Konseling.
///
/// Berdasarkan `RbacSeeder`, permission `bk-kasus.view` hanya dimiliki role
/// `guru_bk`, `admin`, `kepala_sekolah`, dan `wakil_kepala_sekolah` — role
/// `siswa`, `wali`, dan `guru` biasa TIDAK memilikinya sehingga akan melihat
/// `_NoAccessView`. Alur siswa/wali tetap diimplementasikan penuh dan otomatis
/// aktif bila sekolah memberikan izin tersebut lewat pengaturan RBAC.
class BkPage extends StatelessWidget {
  const BkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BkBloc>(),
      child: const _BkView(),
    );
  }
}

class _BkView extends StatefulWidget {
  const _BkView();

  @override
  State<_BkView> createState() => _BkViewState();
}

class _BkViewState extends State<_BkView> {
  UserEntity? _user;
  String _role = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;

      if (authState is! AuthAuthenticated) {
        context.read<BkBloc>().add(
          const BkLoadRequested(role: '', canView: false, canCreate: false),
        );
        return;
      }

      final user = authState.user;
      _user = user;
      _role = bkNormalisasiRole(user.role);

      context.read<BkBloc>().add(
        BkLoadRequested(
          role: _role,
          profileId: user.profile?['id'] as int?,
          canView: user.hasPermission(bkPermKasusView),
          canCreate: user.hasPermission(bkPermKasusCreate),
        ),
      );
    });
  }

  Future<void> _bukaDetail(BuildContext context, BkKasusEntity kasus) async {
    final user = _user;
    final bloc = context.read<BkBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BkDetailPage(
          kasus: kasus,
          tampilkanNamaSiswa: _role != 'siswa',
          canViewSesi: user?.hasPermission(bkPermSesiView) ?? false,
          canViewHasil: user?.hasPermission(bkPermHasilView) ?? false,
          canViewTindakan: user?.hasPermission(bkPermTindakanView) ?? false,
          canManageSesi: user?.hasPermission(bkPermSesiManage) ?? false,
          canManageHasil: user?.hasPermission(bkPermHasilManage) ?? false,
          canManageTindakan:
              user?.hasPermission(bkPermTindakanManage) ?? false,
        ),
      ),
    );
    if (!mounted) return;
    // Muat ulang setelah kembali — sesi/hasil/tindakan baru bisa mengubah data.
    bloc.add(const BkRefreshRequested());
  }

  Future<void> _bukaFormKasus(BuildContext context) async {
    final user = _user;
    final bloc = context.read<BkBloc>();
    final berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BkKasusFormPage(
          // `profile['id']` = id guru untuk role guru. Untuk role `guru_bk`
          // backend bisa mengirim profile null (UserResource hanya memetakan
          // kode GURU/SISWA/WALI_SISWA) — form menyediakan isian ID guru
          // manual sebagai cadangan.
          guruIdAwal: _role == 'guru'
              ? (user?.profile?['id'] as int?)
              : null,
          bolehCariSiswa: user?.hasPermission(bkPermSiswaView) ?? false,
        ),
      ),
    );
    if (!mounted || berhasil != true) return;
    bloc.add(const BkRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bimbingan Konseling'),
        centerTitle: true,
      ),
      floatingActionButton: BlocBuilder<BkBloc, BkState>(
        builder: (context, state) {
          if (state is! BkLoaded || !state.canCreate) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _bukaFormKasus(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Kasus Baru'),
          );
        },
      ),
      body: BlocBuilder<BkBloc, BkState>(
        builder: (context, state) {
          if (state is BkNoAccess) {
            return _NoAccessView(message: state.message);
          }
          if (state is BkError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<BkBloc>().add(const BkRefreshRequested()),
            );
          }
          if (state is BkLoaded) {
            return _LoadedView(
              state: state,
              onRefresh: () async =>
                  context.read<BkBloc>().add(const BkRefreshRequested()),
              onTapKasus: (kasus) => _bukaDetail(context, kasus),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// ── Loaded ────────────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final BkLoaded state;
  final Future<void> Function() onRefresh;
  final void Function(BkKasusEntity) onTapKasus;

  const _LoadedView({
    required this.state,
    required this.onRefresh,
    required this.onTapKasus,
  });

  static const List<String> _statusFilter = [
    'dibuka',
    'proses',
    'selesai',
    'dirujuk',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (state.tampilkanNamaSiswa) _SearchBar(nilaiAwal: state.search),
        _StatusFilterBar(
          statusList: _statusFilter,
          hitung: state.hitungStatus,
          terpilih: state.filterStatus,
          total: state.totalSemua,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: state.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: _EmptyView(
                          message: state.adaFilterAktif
                              ? 'Tidak ada kasus yang cocok dengan filter.'
                              : 'Belum ada kasus bimbingan konseling.',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final kasus = state.items[i];
                      return _KasusCard(
                        kasus: kasus,
                        tampilkanNamaSiswa: state.tampilkanNamaSiswa,
                        onTap: () => onTapKasus(kasus),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Pencarian ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final String nilaiAwal;

  const _SearchBar({required this.nilaiAwal});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextFormField(
        initialValue: nilaiAwal,
        onChanged: (v) => context.read<BkBloc>().add(BkSearchChanged(v)),
        decoration: const InputDecoration(
          hintText: 'Cari siswa, NIS, atau jenis kasus…',
          prefixIcon: Icon(Icons.search, size: 20),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13.5),
      ),
    );
  }
}

// ── Filter status ─────────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final List<String> statusList;
  final Map<String, int> hitung;
  final String? terpilih;
  final int total;

  const _StatusFilterBar({
    required this.statusList,
    required this.hitung,
    required this.terpilih,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: AppColors.cardBg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: statusList.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _ChipStatus(
              label: 'Semua ($total)',
              warna: AppColors.primary,
              aktif: terpilih == null,
              onTap: () =>
                  context.read<BkBloc>().add(const BkStatusFilterChanged(null)),
            );
          }
          final status = statusList[i - 1];
          final jumlah = hitung[status] ?? 0;
          return _ChipStatus(
            label: '$status ($jumlah)',
            warna: bkWarnaStatus(status),
            ikon: bkIkonStatus(status),
            aktif: terpilih == status,
            onTap: () =>
                context.read<BkBloc>().add(BkStatusFilterChanged(status)),
          );
        },
      ),
    );
  }
}

class _ChipStatus extends StatelessWidget {
  final String label;
  final Color warna;
  final IconData? ikon;
  final bool aktif;
  final VoidCallback onTap;

  const _ChipStatus({
    required this.label,
    required this.warna,
    this.ikon,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? warna : warna.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: warna.withAlpha(aktif ? 255 : 90)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ikon != null) ...[
              Icon(ikon, size: 13, color: aktif ? Colors.white : warna),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: aktif ? Colors.white : warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kartu kasus ───────────────────────────────────────────────────────────────

class _KasusCard extends StatelessWidget {
  final BkKasusEntity kasus;
  final bool tampilkanNamaSiswa;
  final VoidCallback onTap;

  const _KasusCard({
    required this.kasus,
    required this.tampilkanNamaSiswa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final judul =
        kasus.judul ??
        kasus.jenisNama ??
        (kasus.jenisKode != null ? 'Jenis ${kasus.jenisKode}' : 'Kasus BK');
    final subjudulSiswa = tampilkanNamaSiswa && kasus.siswaNama != null
        ? '${kasus.siswaNama}${kasus.siswaNis != null ? ' · NIS ${kasus.siswaNis}' : ''}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: bkWarnaStatus(kasus.statusLabel).withAlpha(24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      size: 20,
                      color: bkWarnaStatus(kasus.statusLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          judul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subjudulSiswa != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subjudulSiswa,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BkStatusBadge(label: kasus.statusLabel),
                ],
              ),
              if (kasus.keterangan != null && kasus.keterangan!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  kasus.keterangan!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 13,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    bkFormatTanggalDate(kasus.tanggalDate),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (kasus.guruNama != null) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.support_agent_outlined,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        kasus.guruNama!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tanpa akses ───────────────────────────────────────────────────────────────

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

// ── Error ─────────────────────────────────────────────────────────────────────

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

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.psychology_outlined,
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
            const SizedBox(height: 6),
            const Text(
              'Tarik ke bawah untuk memuat ulang.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
