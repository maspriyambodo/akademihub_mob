import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/kalender_agenda_item.dart';
import '../../domain/entities/kalender_tipe_entity.dart';
import '../bloc/kalender_bloc.dart';
import '../widgets/kalender_agenda_card.dart';
import '../widgets/kalender_konteks_header.dart';
import '../widgets/kalender_month_selector.dart';
import '../widgets/kalender_visuals.dart';
import 'kalender_detail_page.dart';

/// Permission backend untuk endpoint kalender (grup `admin` di `routes/api.php`).
const String _permKalender = 'kalender-akademik.view';
const String _permHarian = 'kalender-harian.view';
const String _permTipe = 'kalender-tipe.view';

class KalenderPage extends StatelessWidget {
  const KalenderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<KalenderBloc>(),
      child: const _KalenderView(),
    );
  }
}

class _KalenderView extends StatefulWidget {
  const _KalenderView();

  @override
  State<_KalenderView> createState() => _KalenderViewState();
}

class _KalenderViewState extends State<_KalenderView> {
  late int _bulan;
  late int _tahun;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulan = now.month;
    _tahun = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;

      if (authState is! AuthAuthenticated) {
        context.read<KalenderBloc>().add(
          KalenderLoadRequested(
            role: '',
            bolehLihatKalender: false,
            bolehLihatHarian: false,
            bolehLihatTipe: false,
            bulan: _bulan,
            tahun: _tahun,
          ),
        );
        return;
      }

      final user = authState.user;
      context.read<KalenderBloc>().add(
        KalenderLoadRequested(
          role: _labelRole(user.role),
          bolehLihatKalender: user.hasPermission(_permKalender),
          bolehLihatHarian: user.hasPermission(_permHarian),
          bolehLihatTipe: user.hasPermission(_permTipe),
          bulan: _bulan,
          tahun: _tahun,
        ),
      );
    });
  }

  /// `sys_roles.code` disimpan UPPERCASE (`SISWA`, `GURU`, `WALI_SISWA`,
  /// `ADMIN`) sementara `UserEntity.role` bisa lowercase. Normalisasi ke
  /// lowercase dan cek `wali` SEBELUM `siswa` (karena `WALI_SISWA` memuat
  /// substring `siswa`).
  String _labelRole(String? role) {
    final r = (role ?? '').trim().toLowerCase();
    if (r.isEmpty) return '';
    if (r.contains('wali')) return 'wali';
    if (r.contains('guru')) return 'guru';
    if (r.contains('siswa')) return 'siswa';
    if (r.contains('admin')) return 'admin';
    return r;
  }

  void _gantiBulan(int delta) {
    setState(() {
      var b = _bulan + delta;
      var t = _tahun;
      while (b < 1) {
        b += 12;
        t--;
      }
      while (b > 12) {
        b -= 12;
        t++;
      }
      _bulan = b;
      _tahun = t;
    });
    context.read<KalenderBloc>().add(
      KalenderMonthChanged(bulan: _bulan, tahun: _tahun),
    );
  }

  void _kembaliKeBulanIni() {
    final now = DateTime.now();
    setState(() {
      _bulan = now.month;
      _tahun = now.year;
    });
    context.read<KalenderBloc>().add(
      KalenderMonthChanged(bulan: _bulan, tahun: _tahun),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender Akademik'), centerTitle: true),
      body: BlocBuilder<KalenderBloc, KalenderState>(
        builder: (context, state) {
          if (state is KalenderForbidden) {
            return _NoAccessView(message: state.message);
          }
          if (state is KalenderError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<KalenderBloc>().add(
                const KalenderRefreshRequested(),
              ),
            );
          }

          return Column(
            children: [
              KalenderMonthSelector(
                bulan: _bulan,
                tahun: _tahun,
                onPrev: () => _gantiBulan(-1),
                onNext: () => _gantiBulan(1),
                onKembaliKeBulanIni: _kembaliKeBulanIni,
              ),
              if (state is KalenderLoaded)
                KalenderKonteksHeader(konteks: state.konteks),
              if (state is KalenderLoaded && state.tipeList.isNotEmpty)
                _TipeFilterBar(
                  tipeList: state.tipeList,
                  terpilih: state.filterTipeId,
                  onPilih: (id) => context.read<KalenderBloc>().add(
                    KalenderTipeFilterChanged(id),
                  ),
                ),
              Expanded(
                child: state is KalenderLoaded
                    ? _LoadedView(
                        state: state,
                        onRefresh: () async {
                          context.read<KalenderBloc>().add(
                            const KalenderRefreshRequested(),
                          );
                        },
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

// ── Filter tipe ───────────────────────────────────────────────────────────────

class _TipeFilterBar extends StatelessWidget {
  final List<KalenderTipeEntity> tipeList;
  final int? terpilih;
  final ValueChanged<int?> onPilih;

  const _TipeFilterBar({
    required this.tipeList,
    required this.terpilih,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    // Tanpa tinggi tetap: deretan chip digulir horizontal sehingga tetap utuh
    // di layar sempit dan ikut tumbuh saat font sistem diperbesar.
    return Container(
      width: double.infinity,
      color: AppColors.cardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(pad.left, 7, pad.right, 7),
        child: Row(
          children: [
            _ChipFilter(
              label: 'Semua',
              warna: AppColors.primary,
              aktif: terpilih == null,
              onTap: () => onPilih(null),
            ),
            for (final tipe in tipeList) ...[
              const SizedBox(width: 6),
              _ChipFilter(
                label: tipe.nama,
                warna: warnaTipe(tipe),
                ikon: ikonTipe(tipe),
                aktif: terpilih == tipe.id,
                onTap: () => onPilih(terpilih == tipe.id ? null : tipe.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  final String label;
  final Color warna;
  final IconData? ikon;
  final bool aktif;
  final VoidCallback onTap;

  const _ChipFilter({
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
        // Tanpa `alignment` supaya kotak menyesuaikan isi (dengan `alignment`
        // + maxWidth semua chip akan melebar penuh ke batas tersebut).
        constraints: const BoxConstraints(minHeight: 32, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: aktif ? Colors.white : warna,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loaded ────────────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final KalenderLoaded state;
  final Future<void> Function() onRefresh;

  const _LoadedView({required this.state, required this.onRefresh});

  void _bukaDetail(BuildContext context, KalenderAgendaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => KalenderDetailPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sekarang = DateTime.now();

    if (state.kosong) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: Responsive.tinggiSheet(context, rasio: 0.55),
              child: _EmptyView(
                message: state.filterTipeId != null
                    ? 'Tidak ada agenda berkategori ini pada '
                          '${labelBulan(state.bulan)} ${state.tahun}'
                    : 'Belum ada agenda pada '
                          '${labelBulan(state.bulan)} ${state.tahun}',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.lebarKontenMaks(context),
          ),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Agenda Hari Ini ─────────────────────────────────────────────
              if (state.agendaHariIni.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _JudulSeksi(
                    ikon: Icons.wb_sunny_outlined,
                    teks: 'Agenda Hari Ini',
                    keterangan: formatTanggalPanjang(sekarang),
                    warna: AppColors.warning,
                    jumlah: state.agendaHariIni.length,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => KalenderAgendaCard(
                      item: state.agendaHariIni[i],
                      sorotHariIni: true,
                      onTap: () => _bukaDetail(context, state.agendaHariIni[i]),
                    ),
                    childCount: state.agendaHariIni.length,
                  ),
                ),
              ],

              // ── Agenda bulan terpilih ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _JudulSeksi(
                  ikon: Icons.calendar_month_outlined,
                  teks: '${labelBulan(state.bulan)} ${state.tahun}',
                  keterangan: '${state.totalBulanIni} agenda',
                  warna: AppColors.primary,
                ),
              ),

              if (state.grupBulanIni.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Text(
                      state.agendaHariIni.isNotEmpty
                          ? 'Tidak ada agenda lain pada bulan ini.'
                          : 'Belum ada agenda pada bulan ini.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

              for (final grup in state.grupBulanIni) ...[
                SliverToBoxAdapter(
                  child: _HeaderTanggal(
                    tanggal: grup.tanggalDate,
                    hariIni: sekarang,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => KalenderAgendaCard(
                      item: grup.items[i],
                      onTap: () => _bukaDetail(context, grup.items[i]),
                    ),
                    childCount: grup.items.length,
                  ),
                ),
              ],

              if (!state.harianTersedia)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Catatan agenda harian tidak ditampilkan karena akun '
                            'Anda tidak memiliki izin "kalender-harian.view".',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Judul seksi ───────────────────────────────────────────────────────────────

class _JudulSeksi extends StatelessWidget {
  final IconData ikon;
  final String teks;
  final String? keterangan;
  final Color warna;
  final int? jumlah;

  const _JudulSeksi({
    required this.ikon,
    required this.teks,
    this.keterangan,
    required this.warna,
    this.jumlah,
  });

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 4),
      child: Row(
        children: [
          Icon(ikon, size: 17, color: warna),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              teks,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: warna,
              ),
            ),
          ),
          if (jumlah != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: warna,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$jumlah',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (keterangan != null)
            Flexible(
              child: Text(
                keterangan!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Header tanggal (pengelompokan) ────────────────────────────────────────────

class _HeaderTanggal extends StatelessWidget {
  final DateTime? tanggal;
  final DateTime hariIni;

  const _HeaderTanggal({required this.tanggal, required this.hariIni});

  @override
  Widget build(BuildContext context) {
    final d = tanggal;
    if (d == null) return const SizedBox.shrink();
    final isHariIni =
        d.year == hariIni.year &&
        d.month == hariIni.month &&
        d.day == hariIni.day;

    final pad = Responsive.pagePadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isHariIni ? AppColors.warning : AppColors.divider,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Teks tanggal + label relatif diberi porsi jauh lebih besar dari
          // garis pemisah supaya tidak terpotong di layar sempit.
          Flexible(
            flex: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    formatTanggalPanjang(d),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isHariIni
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    labelRelatif(d, hariIni),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: AppColors.divider)),
        ],
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
              Icons.event_busy_outlined,
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
