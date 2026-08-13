import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/tmb_hasil_entity.dart';
import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/entities/tmb_tes_entity.dart';
import '../bloc/tmb_hasil_bloc.dart';
import '../widgets/tmb_widgets.dart';

/// Halaman hasil tes satu peserta: skor per aspek (bar sederhana, widget
/// Flutter murni) plus interpretasi/rekomendasi bila tersedia.
class TmbHasilPage extends StatelessWidget {
  final TmbPesertaEntity peserta;

  /// Fallback info tes bila relasi `tes` pada [peserta] kosong.
  final TmbTesEntity? tes;

  final bool viaHasilEndpoint;
  final int? siswaIdUntukRefresh;

  const TmbHasilPage({
    super.key,
    required this.peserta,
    this.tes,
    this.viaHasilEndpoint = false,
    this.siswaIdUntukRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TmbHasilBloc>()
        ..add(
          TmbHasilStarted(
            peserta: peserta,
            viaHasilEndpoint: viaHasilEndpoint,
            siswaIdUntukRefresh: siswaIdUntukRefresh,
          ),
        ),
      child: _HasilView(tesFallback: tes),
    );
  }
}

class _HasilView extends StatelessWidget {
  final TmbTesEntity? tesFallback;

  const _HasilView({this.tesFallback});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Tes'), centerTitle: true),
      body: BlocBuilder<TmbHasilBloc, TmbHasilState>(
        builder: (context, state) {
          if (state is TmbHasilInitial || state is TmbHasilLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TmbHasilError) {
            return _HasilError(
              message: state.message,
              onRetry: () => context.read<TmbHasilBloc>().add(
                const TmbHasilRefreshRequested(),
              ),
            );
          }
          if (state is TmbHasilLoaded) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.lebarKontenMaks(context),
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<TmbHasilBloc>().add(
                      const TmbHasilRefreshRequested(),
                    );
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: Responsive.pagePadding(context),
                    children: [
                      _KartuInfo(state: state, tesFallback: tesFallback),
                      const SizedBox(height: 10),
                      if (state.hasil.isEmpty)
                        const _HasilKosong()
                      else ...[
                        _KartuSkor(state: state),
                        ..._bagianRekomendasi(state),
                      ],
                      const SizedBox(height: 24),
                    ],
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

  List<Widget> _bagianRekomendasi(TmbHasilLoaded state) {
    final punyaCatatan = state.hasil
        .where(
          (h) =>
              (h.rekomendasi != null && h.rekomendasi!.trim().isNotEmpty) ||
              (h.aspekDeskripsi != null && h.aspekDeskripsi!.trim().isNotEmpty),
        )
        .toList();
    if (punyaCatatan.isEmpty) return const [];

    return [
      const SizedBox(height: 10),
      _KartuBungkus(
        judul: 'Interpretasi & Rekomendasi',
        icon: Icons.lightbulb_outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final h in punyaCatatan) _RekomendasiItem(hasil: h)],
        ),
      ),
    ];
  }
}

// ── Kartu info peserta/tes ───────────────────────────────────────────────────

class _KartuInfo extends StatelessWidget {
  final TmbHasilLoaded state;
  final TmbTesEntity? tesFallback;

  const _KartuInfo({required this.state, this.tesFallback});

  @override
  Widget build(BuildContext context) {
    final peserta = state.peserta;
    final tes = peserta.tes ?? tesFallback;

    return _KartuBungkus(
      judul: tes?.namaTes ?? 'Tes Minat Bakat',
      icon: Icons.psychology_outlined,
      trailing: TmbStatusChip.keikutsertaan(peserta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tes != null)
            TmbInfoRow(
              icon: Icons.category_outlined,
              text: 'Tipe: ${tes.labelTipe}',
            ),
          if (peserta.siswaNama != null)
            TmbInfoRow(
              icon: Icons.person_outline,
              text:
                  '${peserta.siswaNama}'
                  '${peserta.siswaNis != null ? ' (${peserta.siswaNis})' : ''}'
                  '${peserta.kelasNama != null ? ' • ${peserta.kelasNama}' : ''}',
            ),
          TmbInfoRow(
            icon: Icons.play_circle_outline,
            text: 'Mulai: ${formatTmbTanggalJam(peserta.waktuMulaiDate)}',
          ),
          TmbInfoRow(
            icon: Icons.flag_outlined,
            text: 'Selesai: ${formatTmbTanggalJam(peserta.waktuSelesaiDate)}',
          ),
        ],
      ),
    );
  }
}

// ── Kartu skor per aspek ─────────────────────────────────────────────────────

class _KartuSkor extends StatelessWidget {
  final TmbHasilLoaded state;

  const _KartuSkor({required this.state});

  @override
  Widget build(BuildContext context) {
    return _KartuBungkus(
      judul: 'Skor per Aspek',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          for (final h in state.hasil)
            TmbAspekBar(hasil: h, skorTotalTertinggi: state.skorTotalTertinggi),
        ],
      ),
    );
  }
}

// ── Item rekomendasi ─────────────────────────────────────────────────────────

class _RekomendasiItem extends StatelessWidget {
  final TmbHasilEntity hasil;

  const _RekomendasiItem({required this.hasil});

  @override
  Widget build(BuildContext context) {
    final rekomendasi = hasil.rekomendasi?.trim();
    final deskripsi = hasil.aspekDeskripsi?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hasil.namaTampil,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasil.kategoriTampil != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    hasil.kategoriTampil!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (deskripsi != null && deskripsi.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              deskripsi,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (rekomendasi != null && rekomendasi.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              rekomendasi,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Kartu pembungkus seragam ─────────────────────────────────────────────────

class _KartuBungkus extends StatelessWidget {
  final String judul;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _KartuBungkus({
    required this.judul,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Flexible(child: trailing!),
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ── Hasil kosong ─────────────────────────────────────────────────────────────

class _HasilKosong extends StatelessWidget {
  const _HasilKosong();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.hourglass_empty, size: 48, color: AppColors.textHint),
          SizedBox(height: 10),
          Text(
            'Hasil belum tersedia. Skor dihitung otomatis saat tes '
            'diselesaikan — tarik ke bawah untuk memuat ulang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error ────────────────────────────────────────────────────────────────────

class _HasilError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HasilError({required this.message, required this.onRetry});

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
