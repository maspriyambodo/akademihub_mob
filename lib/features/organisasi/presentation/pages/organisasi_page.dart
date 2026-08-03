import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/organisasi_entity.dart';
import '../bloc/organisasi_bloc.dart';
import '../widgets/organisasi_widgets.dart';
import 'organisasi_detail_page.dart';

/// Permission backend untuk grup route `/api/v1/organisasi`.
/// Siswa & wali punya `organisasi.view` + `organisasi.anggota.view`;
/// guru TIDAK punya izin organisasi sama sekali (verifikasi RbacSeeder).
const String _permOrganisasi = 'organisasi.view';

/// Halaman utama modul Organisasi (OSIS/organisasi sekolah lainnya).
///
/// Read-only di mobile: menampilkan daftar organisasi, lalu struktur
/// kepengurusan per organisasi di halaman detail. Aksi kelola dilakukan
/// admin lewat web.
class OrganisasiPage extends StatelessWidget {
  const OrganisasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrganisasiBloc>(),
      child: const _OrganisasiView(),
    );
  }
}

class _OrganisasiView extends StatefulWidget {
  const _OrganisasiView();

  @override
  State<_OrganisasiView> createState() => _OrganisasiViewState();
}

class _OrganisasiViewState extends State<_OrganisasiView> {
  final TextEditingController _cariController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;

      final bolehLihat =
          authState is AuthAuthenticated &&
          authState.user.hasPermission(_permOrganisasi);

      context.read<OrganisasiBloc>().add(
        OrganisasiLoadRequested(bolehLihat: bolehLihat),
      );
    });
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  void _bukaDetail(BuildContext context, OrganisasiEntity organisasi) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrganisasiDetailPage(
          organisasiId: organisasi.id,
          namaAwal: organisasi.nama,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organisasi'), centerTitle: true),
      body: BlocBuilder<OrganisasiBloc, OrganisasiState>(
        builder: (context, state) {
          if (state is OrganisasiForbidden) {
            return _NoAccessView(message: state.message);
          }
          if (state is OrganisasiError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<OrganisasiBloc>().add(
                const OrganisasiRefreshRequested(),
              ),
            );
          }
          if (state is OrganisasiLoaded) {
            return _LoadedView(
              state: state,
              cariController: _cariController,
              onTapOrganisasi: (organisasi) => _bukaDetail(context, organisasi),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// ── Konten saat data termuat ─────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final OrganisasiLoaded state;
  final TextEditingController cariController;
  final ValueChanged<OrganisasiEntity> onTapOrganisasi;

  const _LoadedView({
    required this.state,
    required this.cariController,
    required this.onTapOrganisasi,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrganisasiBloc>();
    final tampil = state.tampil;
    final daftarPeriode = state.daftarPeriode;

    return Column(
      children: [
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: [
              TextField(
                controller: cariController,
                onChanged: (value) => bloc.add(OrganisasiSearchChanged(value)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cari nama, kode, atau pembina',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: state.search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            cariController.clear();
                            bloc.add(const OrganisasiSearchChanged(''));
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
                  _StatusChip(
                    label: 'Aktif',
                    filter: StatusOrganisasiFilter.aktif,
                    selected:
                        state.filterStatus == StatusOrganisasiFilter.aktif,
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'Semua Status',
                    filter: StatusOrganisasiFilter.semua,
                    selected:
                        state.filterStatus == StatusOrganisasiFilter.semua,
                  ),
                ],
              ),
              if (daftarPeriode.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _PeriodeChip(
                        label: 'Semua Periode',
                        periode: null,
                        selected: state.filterPeriode == null,
                      ),
                      for (final tahun in daftarPeriode)
                        _PeriodeChip(
                          label: 'Periode $tahun',
                          periode: tahun,
                          selected: state.filterPeriode == tahun,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(const OrganisasiRefreshRequested());
            },
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.lebarKontenMaks(context),
                ),
                child: tampil.isEmpty
                    ? _ScrollableEmpty(
                        message: state.search.trim().isNotEmpty
                            ? 'Tidak ada organisasi yang cocok dengan pencarian'
                            : 'Belum ada data organisasi',
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 6, bottom: 20),
                        itemCount: tampil.length,
                        itemBuilder: (context, index) {
                          final organisasi = tampil[index];
                          return OrganisasiCard(
                            organisasi: organisasi,
                            onTap: () => onTapOrganisasi(organisasi),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final StatusOrganisasiFilter filter;
  final bool selected;

  const _StatusChip({
    required this.label,
    required this.filter,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<OrganisasiBloc>().add(
          OrganisasiStatusFilterChanged(filter),
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

class _PeriodeChip extends StatelessWidget {
  final String label;
  final int? periode;
  final bool selected;

  const _PeriodeChip({
    required this.label,
    required this.periode,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<OrganisasiBloc>().add(
          OrganisasiPeriodeFilterChanged(periode),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
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

// ── Empty view yang tetap bisa di-scroll (agar RefreshIndicator jalan) ───────

class _ScrollableEmpty extends StatelessWidget {
  final String message;

  const _ScrollableEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: Responsive.tinggiSheet(context, rasio: 0.55),
          child: _EmptyView(message: message),
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
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_2_outlined,
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

// ── No Access View ───────────────────────────────────────────────────────────

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
