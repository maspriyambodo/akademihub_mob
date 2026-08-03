import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/entities/tmb_tes_entity.dart';
import '../bloc/tmb_peserta_bloc.dart';
import '../widgets/tmb_widgets.dart';
import 'tmb_hasil_page.dart';

/// Daftar peserta satu tes (mode staf, read-only). Tap peserta yang punya
/// hasil untuk melihat skor per aspeknya.
class TmbPesertaPage extends StatelessWidget {
  final TmbTesEntity tes;
  final bool canViewHasilEndpoint;

  const TmbPesertaPage({
    super.key,
    required this.tes,
    this.canViewHasilEndpoint = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TmbPesertaBloc>()..add(TmbPesertaLoadRequested(tes.id)),
      child: _PesertaView(tes: tes, canViewHasilEndpoint: canViewHasilEndpoint),
    );
  }
}

class _PesertaView extends StatelessWidget {
  final TmbTesEntity tes;
  final bool canViewHasilEndpoint;

  const _PesertaView({required this.tes, required this.canViewHasilEndpoint});

  void _bukaHasil(BuildContext context, TmbPesertaEntity peserta) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TmbHasilPage(
          peserta: peserta,
          tes: tes,
          viaHasilEndpoint: canViewHasilEndpoint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peserta Tes'), centerTitle: true),
      body: BlocBuilder<TmbPesertaBloc, TmbPesertaState>(
        builder: (context, state) {
          if (state is TmbPesertaInitial || state is TmbPesertaLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TmbPesertaNoAccess) {
            return _PesertaNoAccess(message: state.message);
          }
          if (state is TmbPesertaError) {
            return _PesertaError(
              message: state.message,
              onRetry: () => context.read<TmbPesertaBloc>().add(
                const TmbPesertaRefreshRequested(),
              ),
            );
          }
          if (state is TmbPesertaLoaded) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.lebarKontenMaks(context),
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<TmbPesertaBloc>().add(
                      const TmbPesertaRefreshRequested(),
                    );
                  },
                  child: state.pesertaList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: Responsive.tinggiSheet(
                                context,
                                rasio: 0.6,
                              ),
                              child: const _PesertaEmpty(),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: state.pesertaList.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _RingkasanHeader(tes: tes, state: state);
                            }
                            final peserta = state.pesertaList[index - 1];
                            return _PesertaCard(
                              peserta: peserta,
                              onTap:
                                  peserta.isSelesai ||
                                      peserta.hasil.isNotEmpty
                                  ? () => _bukaHasil(context, peserta)
                                  : null,
                            );
                          },
                        ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Header ringkasan ─────────────────────────────────────────────────────────

class _RingkasanHeader extends StatelessWidget {
  final TmbTesEntity tes;
  final TmbPesertaLoaded state;

  const _RingkasanHeader({required this.tes, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tes.namaTes,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              TmbStatusChip(label: tes.labelTipe, color: AppColors.primary),
              TmbStatusChip.tes(tes),
            ],
          ),
          const SizedBox(height: 6),
          TmbInfoRow(
            icon: Icons.groups_outlined,
            text:
                '${state.pesertaList.length} peserta • '
                '${state.jumlahSelesai} selesai',
          ),
        ],
      ),
    );
  }
}

// ── Kartu peserta ────────────────────────────────────────────────────────────

class _PesertaCard extends StatelessWidget {
  final TmbPesertaEntity peserta;
  final VoidCallback? onTap;

  const _PesertaCard({required this.peserta, this.onTap});

  @override
  Widget build(BuildContext context) {
    final nama = peserta.siswaNama ?? 'Siswa #${peserta.siswaId}';
    final inisial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';
    final detail = [
      if (peserta.siswaNis != null) 'NIS ${peserta.siswaNis}',
      if (peserta.kelasNama != null) peserta.kelasNama!,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.cardBg,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withAlpha(24),
                child: Text(
                  inisial,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (peserta.isBerjalan &&
                        peserta.progressPersen != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Progress ${peserta.progressPersen}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
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
                  TmbStatusChip.keikutsertaan(peserta),
                  if (onTap != null) ...[
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textHint,
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

// ── Empty / error / no access ────────────────────────────────────────────────

class _PesertaEmpty extends StatelessWidget {
  const _PesertaEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'Belum ada peserta pada tes ini.\nCatatan: backend membatasi '
              'visibilitas per sesi — wali kelas hanya melihat siswa '
              'perwaliannya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PesertaError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PesertaError({required this.message, required this.onRetry});

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

class _PesertaNoAccess extends StatelessWidget {
  final String message;
  const _PesertaNoAccess({required this.message});

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
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
