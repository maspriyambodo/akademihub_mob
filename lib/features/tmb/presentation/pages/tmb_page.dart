import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/tmb_bloc.dart';
import '../widgets/tmb_widgets.dart';
import 'tmb_hasil_page.dart';
import 'tmb_pengerjaan_page.dart';
import 'tmb_peserta_page.dart';

/// Halaman utama modul Tes Minat Bakat (TMB).
///
/// - Siswa: daftar tes di kelasnya + status keikutsertaan, dengan alur
///   mulai → mengerjakan → hasil.
/// - Staf (admin/guru BK): daftar seluruh tes, tap untuk melihat peserta
///   beserta hasilnya (read-only).
class TmbPage extends StatelessWidget {
  const TmbPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TmbBloc>(),
      child: const _TmbView(),
    );
  }
}

class _TmbView extends StatefulWidget {
  const _TmbView();

  @override
  State<_TmbView> createState() => _TmbViewState();
}

class _TmbViewState extends State<_TmbView> {
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

      context.read<TmbBloc>().add(
        TmbLoadRequested(
          role: role,
          siswaId: role == 'siswa' ? profileId : null,
          kelasId: role == 'siswa' ? _kelasIdSiswa(profile) : null,
          hasViewTes: user.hasPermission('tes-minat-bakat.view'),
          canDaftar: user.hasPermission('tes-minat-bakat-peserta.create'),
          canMulai: user.hasPermission('tes-minat-bakat-peserta.mulai'),
          canSelesaikan: user.hasPermission(
            'tes-minat-bakat-peserta.selesaikan',
          ),
          canKirimJawaban: user.hasPermission('tes-minat-bakat-jawaban.create'),
          canViewPeserta: user.hasPermission('tes-minat-bakat-peserta.view'),
          canViewPertanyaanEndpoint: user.hasPermission(
            'tes-minat-bakat-pertanyaan.view',
          ),
          canViewHasilEndpoint: user.hasPermission('tes-minat-bakat-hasil.view'),
        ),
      );
    });
  }

  /// Kode role backend UPPERCASE (`SISWA`/`GURU`/`WALI_SISWA`/`GURU_BK`/...).
  /// `wali` dicek lebih dulu karena `WALI_SISWA` memuat kata `siswa`.
  String _normalizeRole(String? raw) {
    final r = (raw ?? '').toLowerCase();
    if (r.contains('wali')) return 'wali';
    if (r.contains('guru')) return 'guru';
    if (r.contains('siswa')) return 'siswa';
    return 'admin';
  }

  int? _kelasIdSiswa(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final kelas = profile['kelas'];
    if (kelas is Map) {
      final id = (kelas['id'] as num?)?.toInt();
      if (id != null) return id;
    }
    return (profile['mst_kelas_id'] as num?)?.toInt() ??
        (profile['kelas_id'] as num?)?.toInt();
  }

  // ── Navigasi ───────────────────────────────────────────────────────────────

  Future<void> _bukaPengerjaan(
    BuildContext context,
    TmbLoaded state,
    TmbTesItem item,
  ) async {
    final bloc = context.read<TmbBloc>();
    final peserta = item.peserta;
    if (peserta == null) return;

    if (peserta.isTerdaftar) {
      final setuju = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mulai Tes'),
          content: Text(
            'Mulai mengerjakan "${item.tes.namaTes}" sekarang?'
            '${item.tes.durasiMenit != null ? '\nDurasi tes: ${item.tes.durasiMenit} menit.' : ''}'
            '\nWaktu mulai akan dicatat oleh sistem.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Mulai'),
            ),
          ],
        ),
      );
      if (setuju != true || !context.mounted) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TmbPengerjaanPage(
          peserta: peserta,
          tes: item.tes,
          viaTesDetail: !state.canViewPertanyaanEndpoint,
          canSelesaikan: state.canSelesaikan,
          siswaIdUntukRefresh: state.siswaId,
        ),
      ),
    );
    // Setelah kembali (baik selesai maupun keluar di tengah) status di
    // daftar dimuat ulang.
    bloc.add(const TmbRefreshRequested());
  }

  void _bukaHasil(BuildContext context, TmbLoaded state, TmbTesItem item) {
    final peserta = item.peserta;
    if (peserta == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TmbHasilPage(
          peserta: peserta,
          tes: item.tes,
          // Endpoint hasil by-peserta error di backend untuk role siswa/wali,
          // jadi jalur endpoint hanya untuk staf.
          viaHasilEndpoint: !state.isModeSiswa && state.canViewHasilEndpoint,
          siswaIdUntukRefresh: state.isModeSiswa ? state.siswaId : null,
        ),
      ),
    );
  }

  void _bukaPeserta(BuildContext context, TmbLoaded state, TmbTesItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TmbPesertaPage(
          tes: item.tes,
          canViewHasilEndpoint: state.canViewHasilEndpoint,
        ),
      ),
    );
  }

  Future<void> _konfirmasiDaftar(BuildContext context, TmbTesItem item) async {
    final bloc = context.read<TmbBloc>();
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Daftar Tes'),
        content: Text(
          'Daftarkan diri Anda sebagai peserta "${item.tes.namaTes}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
    if (setuju == true) {
      bloc.add(TmbDaftarRequested(item.tes.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tes Minat Bakat'), centerTitle: true),
      body: BlocConsumer<TmbBloc, TmbState>(
        listenWhen: (_, current) =>
            current is TmbActionSuccess || current is TmbActionFailure,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is TmbActionSuccess) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is TmbActionFailure) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        buildWhen: (_, current) =>
            current is! TmbActionSuccess && current is! TmbActionFailure,
        builder: (context, state) {
          if (state is TmbInitial || state is TmbLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TmbNoAccess) {
            return _NoAccessView(message: state.message);
          }
          if (state is TmbError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<TmbBloc>().add(const TmbRefreshRequested()),
            );
          }
          if (state is TmbLoaded) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.lebarKontenMaks(context),
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<TmbBloc>().add(const TmbRefreshRequested());
                  },
                  child: state.items.isEmpty
                      ? _ScrollableEmpty(
                          message: state.isModeSiswa
                              ? 'Belum ada tes minat bakat untuk kelas Anda'
                              : 'Belum ada tes minat bakat',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 6, bottom: 24),
                          itemCount:
                              state.items.length +
                              (state.catatan != null ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (state.catatan != null && index == 0) {
                              return TmbCatatanBanner(message: state.catatan!);
                            }
                            final item = state
                                .items[state.catatan != null ? index - 1 : index];
                            return _TesCard(
                              item: item,
                              state: state,
                              onDaftar: () => _konfirmasiDaftar(context, item),
                              onKerjakan: () =>
                                  _bukaPengerjaan(context, state, item),
                              onLihatHasil: () =>
                                  _bukaHasil(context, state, item),
                              onLihatPeserta: () =>
                                  _bukaPeserta(context, state, item),
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

// ── Kartu tes ────────────────────────────────────────────────────────────────

class _TesCard extends StatelessWidget {
  final TmbTesItem item;
  final TmbLoaded state;
  final VoidCallback onDaftar;
  final VoidCallback onKerjakan;
  final VoidCallback onLihatHasil;
  final VoidCallback onLihatPeserta;

  const _TesCard({
    required this.item,
    required this.state,
    required this.onDaftar,
    required this.onKerjakan,
    required this.onLihatHasil,
    required this.onLihatPeserta,
  });

  @override
  Widget build(BuildContext context) {
    final tes = item.tes;
    final peserta = item.peserta;

    final VoidCallback? onTap;
    if (state.isModeSiswa) {
      if (peserta != null && (peserta.isSelesai || peserta.isTimeout)) {
        onTap = peserta.hasil.isNotEmpty || peserta.isSelesai
            ? onLihatHasil
            : null;
      } else if (peserta != null && state.canKirimJawaban) {
        onTap = onKerjakan;
      } else {
        onTap = null;
      }
    } else {
      onTap = state.canViewPeserta ? onLihatPeserta : null;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
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
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            TmbStatusChip(
                              label: tes.labelTipe,
                              color: AppColors.primary,
                            ),
                            TmbStatusChip.tes(tes),
                            if (state.isModeSiswa)
                              TmbStatusChip.keikutsertaan(peserta),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (tes.deskripsi != null && tes.deskripsi!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  tes.deskripsi!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              TmbInfoRow(
                icon: Icons.event_outlined,
                text:
                    'Jadwal: ${formatTmbTanggalJam(tes.waktuMulaiDate)} – '
                    '${formatTmbTanggalJam(tes.waktuSelesaiDate)}',
              ),
              if (tes.durasiMenit != null)
                TmbInfoRow(
                  icon: Icons.timer_outlined,
                  text: 'Durasi: ${tes.durasiMenit} menit',
                ),
              if (tes.semesterNama != null)
                TmbInfoRow(
                  icon: Icons.school_outlined,
                  text: 'Semester: ${tes.semesterNama}',
                ),
              if (state.isModeSiswa &&
                  peserta != null &&
                  peserta.isBerjalan &&
                  peserta.progressPersen != null)
                TmbInfoRow(
                  icon: Icons.donut_large_outlined,
                  text: 'Progress: ${peserta.progressPersen}%',
                ),
              ..._aksi(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _aksi() {
    if (!state.isModeSiswa) {
      if (!state.canViewPeserta) return const [];
      return [
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onLihatPeserta,
            icon: const Icon(Icons.groups_outlined, size: 18),
            label: const Text('Lihat Peserta'),
          ),
        ),
      ];
    }

    final peserta = item.peserta;
    final tes = item.tes;
    Widget? tombol;

    if (peserta == null) {
      if (state.canDaftar && tes.isDibuka && !tes.sudahLewatJadwal) {
        tombol = FilledButton.icon(
          onPressed: onDaftar,
          icon: const Icon(Icons.how_to_reg_outlined, size: 18),
          label: const Text('Daftar'),
        );
      }
    } else if (peserta.isTerdaftar) {
      if (state.canMulai && state.canKirimJawaban && tes.bisaDikerjakan) {
        tombol = FilledButton.icon(
          onPressed: onKerjakan,
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Mulai Tes'),
        );
      }
    } else if (peserta.isBerjalan) {
      if (state.canKirimJawaban) {
        tombol = FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
          onPressed: onKerjakan,
          icon: const Icon(Icons.edit_note_outlined, size: 20),
          label: const Text('Lanjutkan'),
        );
      }
    } else if (peserta.isSelesai) {
      tombol = OutlinedButton.icon(
        onPressed: onLihatHasil,
        icon: const Icon(Icons.bar_chart_rounded, size: 18),
        label: const Text('Lihat Hasil'),
      );
    } else if (peserta.isTimeout && peserta.hasil.isNotEmpty) {
      tombol = OutlinedButton.icon(
        onPressed: onLihatHasil,
        icon: const Icon(Icons.bar_chart_rounded, size: 18),
        label: const Text('Lihat Hasil'),
      );
    }

    if (tombol == null) return const [];
    return [
      const SizedBox(height: 10),
      Align(alignment: Alignment.centerRight, child: tombol),
    ];
  }
}

// ── Empty scrollable (agar RefreshIndicator tetap berfungsi) ─────────────────

class _ScrollableEmpty extends StatelessWidget {
  final String message;
  const _ScrollableEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: Responsive.tinggiSheet(context, rasio: 0.6),
          child: _EmptyView(message: message),
        ),
      ],
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────────────

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

// ── Empty view ───────────────────────────────────────────────────────────────

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
          ],
        ),
      ),
    );
  }
}

// ── Tanpa akses ──────────────────────────────────────────────────────────────

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
