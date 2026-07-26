import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/organisasi_entity.dart';
import '../bloc/organisasi_detail_bloc.dart';
import '../widgets/organisasi_widgets.dart';

/// Halaman struktur kepengurusan satu organisasi.
///
/// Dibuka dengan `Navigator.push` dari [OrganisasiPage]. Seluruh data
/// (profil + anggota + jabatan) berasal dari satu panggilan
/// `GET /organisasi/{id}`.
class OrganisasiDetailPage extends StatefulWidget {
  final int organisasiId;
  final String namaAwal;

  const OrganisasiDetailPage({
    super.key,
    required this.organisasiId,
    required this.namaAwal,
  });

  @override
  State<OrganisasiDetailPage> createState() => _OrganisasiDetailPageState();
}

class _OrganisasiDetailPageState extends State<OrganisasiDetailPage> {
  final TextEditingController _cariController = TextEditingController();

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrganisasiDetailBloc>()
        ..add(OrganisasiDetailLoadRequested(widget.organisasiId)),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.namaAwal), centerTitle: true),
        body: BlocBuilder<OrganisasiDetailBloc, OrganisasiDetailState>(
          builder: (context, state) {
            if (state is OrganisasiDetailError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<OrganisasiDetailBloc>().add(
                  const OrganisasiDetailRefreshRequested(),
                ),
              );
            }
            if (state is OrganisasiDetailLoaded) {
              return _LoadedView(state: state, cariController: _cariController);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

// ── Konten saat data termuat ─────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final OrganisasiDetailLoaded state;
  final TextEditingController cariController;

  const _LoadedView({required this.state, required this.cariController});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrganisasiDetailBloc>();
    final struktur = state.struktur;

    return Column(
      children: [
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: [
              TextField(
                controller: cariController,
                onChanged: (value) =>
                    bloc.add(OrganisasiDetailSearchChanged(value)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cari nama anggota, NIS, atau jabatan',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: state.search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            cariController.clear();
                            bloc.add(const OrganisasiDetailSearchChanged(''));
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
                  _FilterChip(
                    label: 'Semua',
                    filter: StatusAnggotaFilter.semua,
                    selected: state.filterStatus == StatusAnggotaFilter.semua,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Aktif',
                    filter: StatusAnggotaFilter.aktif,
                    selected: state.filterStatus == StatusAnggotaFilter.aktif,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Alumni',
                    filter: StatusAnggotaFilter.alumni,
                    selected: state.filterStatus == StatusAnggotaFilter.alumni,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(const OrganisasiDetailRefreshRequested());
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              children: [
                _ProfilCard(state: state),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Struktur Kepengurusan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (struktur.isEmpty)
                  _EmptyStruktur(
                    message: state.detail.anggota.isEmpty
                        ? 'Belum ada anggota terdaftar di organisasi ini'
                        : state.adaFilterAktif
                        ? 'Tidak ada anggota yang cocok dengan '
                              'pencarian/filter'
                        : 'Belum ada anggota terdaftar di organisasi ini',
                  )
                else
                  for (final kelompok in struktur)
                    JabatanStrukturCard(
                      namaJabatan: kelompok.nama,
                      anggota: kelompok.anggota,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Kartu profil organisasi ──────────────────────────────────────────────────

class _ProfilCard extends StatelessWidget {
  final OrganisasiDetailLoaded state;

  const _ProfilCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final OrganisasiEntity organisasi = state.detail.organisasi;
    final deskripsi = organisasi.deskripsi?.trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organisasi.nama,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (organisasi.kode != null)
                        Text(
                          'Kode: ${organisasi.kode}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                OrganisasiStatusBadge(
                  label: organisasi.statusLabel,
                  color: organisasi.isAktif
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ],
            ),
            if (deskripsi != null && deskripsi.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                deskripsi,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            _InfoBaris(
              icon: Icons.person_outline,
              label: 'Pembina',
              nilai: organisasi.hasPembina
                  ? organisasi.pembinaNama!
                  : 'Belum ditetapkan',
            ),
            _InfoBaris(
              icon: Icons.calendar_today_outlined,
              label: 'Periode',
              nilai: organisasi.periodeLabel ?? 'Belum diatur',
            ),
            _InfoBaris(
              icon: Icons.people_outline,
              label: 'Anggota',
              nilai:
                  '${state.detail.totalAnggotaAktif} aktif dari '
                  '${state.detail.totalAnggota} terdaftar',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBaris extends StatelessWidget {
  final IconData icon;
  final String label;
  final String nilai;

  const _InfoBaris({
    required this.icon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip filter status anggota ───────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final StatusAnggotaFilter filter;
  final bool selected;

  const _FilterChip({
    required this.label,
    required this.filter,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<OrganisasiDetailBloc>().add(
          OrganisasiDetailStatusFilterChanged(filter),
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

// ── Empty struktur ───────────────────────────────────────────────────────────

class _EmptyStruktur extends StatelessWidget {
  final String message;

  const _EmptyStruktur({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
      child: Column(
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 56,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
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
