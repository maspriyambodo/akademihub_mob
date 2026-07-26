import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/tmb_pertanyaan_entity.dart';
import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/entities/tmb_tes_entity.dart';
import '../bloc/tmb_pengerjaan_bloc.dart';
import '../widgets/tmb_widgets.dart';
import 'tmb_hasil_page.dart';

/// Halaman pengerjaan tes: satu pertanyaan per layar dengan strip nomor untuk
/// melompat antar pertanyaan.
///
/// Setiap jawaban langsung dikirim ke server (backend melakukan upsert per
/// pertanyaan), sehingga keluar dari halaman ini aman — saat kembali,
/// jawaban tersimpan dimuat ulang dan pengerjaan berlanjut dari pertanyaan
/// pertama yang belum terjawab.
class TmbPengerjaanPage extends StatelessWidget {
  final TmbPesertaEntity peserta;
  final TmbTesEntity tes;
  final bool viaTesDetail;
  final bool canSelesaikan;
  final int? siswaIdUntukRefresh;

  const TmbPengerjaanPage({
    super.key,
    required this.peserta,
    required this.tes,
    required this.viaTesDetail,
    required this.canSelesaikan,
    this.siswaIdUntukRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TmbPengerjaanBloc>()
        ..add(
          TmbPengerjaanStarted(
            peserta: peserta,
            tes: tes,
            viaTesDetail: viaTesDetail,
            pesertaBaruMulai: peserta.isTerdaftar,
          ),
        ),
      child: _PengerjaanView(
        canSelesaikan: canSelesaikan,
        siswaIdUntukRefresh: siswaIdUntukRefresh,
      ),
    );
  }
}

class _PengerjaanView extends StatefulWidget {
  final bool canSelesaikan;
  final int? siswaIdUntukRefresh;

  const _PengerjaanView({
    required this.canSelesaikan,
    this.siswaIdUntukRefresh,
  });

  @override
  State<_PengerjaanView> createState() => _PengerjaanViewState();
}

class _PengerjaanViewState extends State<_PengerjaanView> {
  Timer? _timer;
  final TextEditingController _teksController = TextEditingController();
  int? _teksUntukPertanyaan;

  @override
  void initState() {
    super.initState();
    // Penghitung mundur hanya tampilan (backend tidak menimpa status saat
    // durasi habis) — tiap detik cukup memicu rebuild ringan.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _teksController.dispose();
    super.dispose();
  }

  Duration? _sisaWaktu(TmbPengerjaanLoaded state) {
    final durasi = state.tes.durasiMenit;
    final mulai = state.peserta.waktuMulaiDate;
    if (durasi == null || mulai == null) return null;
    return mulai.add(Duration(minutes: durasi)).difference(DateTime.now());
  }

  String _formatDurasi(Duration d) {
    if (d.isNegative) return 'Waktu habis';
    final jam = d.inHours;
    final menit = (d.inMinutes % 60).toString().padLeft(2, '0');
    final detik = (d.inSeconds % 60).toString().padLeft(2, '0');
    return jam > 0 ? '$jam:$menit:$detik' : '$menit:$detik';
  }

  Future<void> _konfirmasiSelesai(
    BuildContext context,
    TmbPengerjaanLoaded state,
  ) async {
    final bloc = context.read<TmbPengerjaanBloc>();
    final belum = state.jumlahBelumTerjawab;
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Selesaikan Tes'),
        content: Text(
          belum > 0
              ? 'Masih ada $belum pertanyaan yang belum dijawab. Pertanyaan '
                    'tanpa jawaban tidak mendapat skor. Tetap selesaikan?'
              : 'Semua pertanyaan sudah dijawab. Selesaikan tes sekarang? '
                    'Jawaban tidak bisa diubah setelah tes diselesaikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: belum > 0
                ? FilledButton.styleFrom(backgroundColor: AppColors.warning)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    if (setuju == true) {
      bloc.add(const TmbPengerjaanSelesaikanRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengerjaan Tes'), centerTitle: true),
      body: BlocConsumer<TmbPengerjaanBloc, TmbPengerjaanState>(
        listenWhen: (_, current) =>
            current is TmbPengerjaanActionFailure ||
            current is TmbPengerjaanSelesai,
        listener: (context, state) {
          if (state is TmbPengerjaanActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is TmbPengerjaanSelesai) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => TmbHasilPage(
                  peserta: state.peserta,
                  tes: state.peserta.tes,
                  viaHasilEndpoint: false,
                  siswaIdUntukRefresh: widget.siswaIdUntukRefresh,
                ),
              ),
            );
          }
        },
        buildWhen: (_, current) =>
            current is! TmbPengerjaanActionFailure &&
            current is! TmbPengerjaanSelesai,
        builder: (context, state) {
          if (state is TmbPengerjaanInitial || state is TmbPengerjaanLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TmbPengerjaanError) {
            return _PengerjaanError(message: state.message);
          }
          if (state is TmbPengerjaanLoaded) {
            return _buildLoaded(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, TmbPengerjaanLoaded state) {
    final pertanyaan = state.pertanyaan[state.index];
    final sisa = _sisaWaktu(state);

    // Sinkronkan controller teks saat pindah pertanyaan.
    if (_teksUntukPertanyaan != pertanyaan.id) {
      _teksUntukPertanyaan = pertanyaan.id;
      _teksController.text =
          state.jawabanUntuk(pertanyaan.id)?.jawabanTeks ?? '';
    }

    return Column(
      children: [
        _HeaderProgress(state: state, sisa: sisa, formatSisa: _formatDurasi),
        if (state.catatan != null)
          TmbCatatanBanner(
            message: state.catatan!,
            icon: Icons.warning_amber_outlined,
            color: AppColors.warning,
          ),
        _StripNomor(state: state),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _KartuPertanyaan(
              key: ValueKey(pertanyaan.id),
              state: state,
              pertanyaan: pertanyaan,
              teksController: _teksController,
            ),
          ),
        ),
        _BarNavigasi(
          state: state,
          canSelesaikan: widget.canSelesaikan,
          onSelesai: () => _konfirmasiSelesai(context, state),
        ),
      ],
    );
  }
}

// ── Header: progress + sisa waktu ────────────────────────────────────────────

class _HeaderProgress extends StatelessWidget {
  final TmbPengerjaanLoaded state;
  final Duration? sisa;
  final String Function(Duration) formatSisa;

  const _HeaderProgress({
    required this.state,
    required this.sisa,
    required this.formatSisa,
  });

  @override
  Widget build(BuildContext context) {
    final habis = sisa != null && sisa!.isNegative;
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.tes.namaTes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (sisa != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (habis ? AppColors.error : AppColors.primary)
                        .withAlpha(22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: habis ? AppColors.error : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatSisa(sisa!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: habis ? AppColors.error : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 7,
              backgroundColor: AppColors.divider.withAlpha(120),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Terjawab ${state.jumlahTerjawab} dari '
            '${state.jumlahPertanyaan} pertanyaan',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Strip nomor pertanyaan ───────────────────────────────────────────────────

class _StripNomor extends StatelessWidget {
  final TmbPengerjaanLoaded state;

  const _StripNomor({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBg,
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: state.pertanyaan.length,
        itemBuilder: (context, i) {
          final p = state.pertanyaan[i];
          final aktif = i == state.index;
          final terjawab = state.sudahDijawab(p.id);
          final Color latar;
          final Color teks;
          if (aktif) {
            latar = AppColors.primary;
            teks = Colors.white;
          } else if (terjawab) {
            latar = AppColors.success.withAlpha(30);
            teks = AppColors.success;
          } else {
            latar = AppColors.surface;
            teks = AppColors.textSecondary;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.read<TmbPengerjaanBloc>().add(
                TmbPengerjaanIndexChanged(i),
              ),
              child: Container(
                width: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: latar,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: aktif ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: teks,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Kartu pertanyaan + opsi ──────────────────────────────────────────────────

class _KartuPertanyaan extends StatelessWidget {
  final TmbPengerjaanLoaded state;
  final TmbPertanyaanEntity pertanyaan;
  final TextEditingController teksController;

  const _KartuPertanyaan({
    super.key,
    required this.state,
    required this.pertanyaan,
    required this.teksController,
  });

  @override
  Widget build(BuildContext context) {
    final jawaban = state.jawabanUntuk(pertanyaan.id);
    final mengirim = state.sedangMengirim.contains(pertanyaan.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pertanyaan ${state.index + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            if (pertanyaan.aspekNama != null)
              TmbStatusChip(
                label: pertanyaan.aspekNama!,
                color: AppColors.secondary,
              ),
            const Spacer(),
            if (mengirim)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (jawaban != null)
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.success,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          pertanyaan.pertanyaan,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        if (pertanyaan.adaOpsi)
          ...pertanyaan.opsi.map(
            (opsi) => _OpsiTile(
              teks: opsi.teks,
              terpilih: jawaban?.opsiId == opsi.id,
              nonaktif: mengirim,
              onTap: () => context.read<TmbPengerjaanBloc>().add(
                TmbPengerjaanOpsiDipilih(
                  pertanyaanId: pertanyaan.id,
                  opsiId: opsi.id,
                ),
              ),
            ),
          )
        else ...[
          TextField(
            controller: teksController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tulis jawaban Anda di sini',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: mengirim
                  ? null
                  : () => context.read<TmbPengerjaanBloc>().add(
                      TmbPengerjaanTeksDikirim(
                        pertanyaanId: pertanyaan.id,
                        teks: teksController.text,
                      ),
                    ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Simpan Jawaban'),
            ),
          ),
        ],
      ],
    );
  }
}

class _OpsiTile extends StatelessWidget {
  final String teks;
  final bool terpilih;
  final bool nonaktif;
  final VoidCallback onTap;

  const _OpsiTile({
    required this.teks,
    required this.terpilih,
    required this.nonaktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: nonaktif ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: terpilih ? AppColors.primary.withAlpha(18) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: terpilih ? AppColors.primary : AppColors.divider,
              width: terpilih ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                terpilih
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: terpilih ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  teks,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: terpilih ? FontWeight.w600 : FontWeight.w400,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bar navigasi bawah ───────────────────────────────────────────────────────

class _BarNavigasi extends StatelessWidget {
  final TmbPengerjaanLoaded state;
  final bool canSelesaikan;
  final VoidCallback onSelesai;

  const _BarNavigasi({
    required this.state,
    required this.canSelesaikan,
    required this.onSelesai,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TmbPengerjaanBloc>();
    final diAwal = state.index <= 0;
    final diAkhir = state.index >= state.pertanyaan.length - 1;

    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: diAwal
                    ? null
                    : () =>
                          bloc.add(TmbPengerjaanIndexChanged(state.index - 1)),
                icon: const Icon(Icons.chevron_left, size: 20),
                label: const Text('Sebelumnya'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: diAkhir || (state.semuaTerjawab && canSelesaikan)
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: canSelesaikan && !state.sedangMenyelesaikan
                          ? onSelesai
                          : null,
                      icon: state.sedangMenyelesaikan
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Selesaikan'),
                    )
                  : FilledButton.icon(
                      onPressed: () =>
                          bloc.add(TmbPengerjaanIndexChanged(state.index + 1)),
                      icon: const Icon(Icons.chevron_right, size: 20),
                      label: const Text('Berikutnya'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error ────────────────────────────────────────────────────────────────────

class _PengerjaanError extends StatelessWidget {
  final String message;
  const _PengerjaanError({required this.message});

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
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
