import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/ppdb_gelombang_entity.dart';
import '../../domain/entities/ppdb_pendaftar_entity.dart';
import '../../domain/entities/ppdb_statistik_entity.dart';
import '../bloc/ppdb_bloc.dart';
import '../widgets/ppdb_visuals.dart';
import 'ppdb_pendaftar_detail_page.dart';

/// Permission backend untuk grup route `/ppdb` (lihat `routes/api.php`).
const String _permPendaftar = 'ppdb.pendaftaran.view';
const String _permGelombang = 'ppdb.gelombang.view';

/// Halaman monitoring PPDB (Penerimaan Peserta Didik Baru).
///
/// Modul ini untuk staf sekolah: role `admin_ppdb` dan `admin` punya akses
/// penuh, `kepala_sekolah`/`wakil_kepala_sekolah` read-only. Role
/// siswa/guru/wali tidak punya permission `ppdb.*` sama sekali sehingga
/// melihat [_NoAccessView].
class PpdbPage extends StatelessWidget {
  const PpdbPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PpdbBloc>(),
      child: const _PpdbView(),
    );
  }
}

class _PpdbView extends StatefulWidget {
  const _PpdbView();

  @override
  State<_PpdbView> createState() => _PpdbViewState();
}

class _PpdbViewState extends State<_PpdbView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;

      if (authState is! AuthAuthenticated) {
        context.read<PpdbBloc>().add(
          const PpdbLoadRequested(
            role: '',
            bolehLihatPendaftar: false,
            bolehLihatGelombang: false,
          ),
        );
        return;
      }

      final user = authState.user;
      context.read<PpdbBloc>().add(
        PpdbLoadRequested(
          role: (user.role ?? '').trim().toLowerCase(),
          bolehLihatPendaftar: user.hasPermission(_permPendaftar),
          bolehLihatGelombang: user.hasPermission(_permGelombang),
        ),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<PpdbBloc>().add(PpdbSearchChanged(value));
    });
  }

  void _bukaDetail(PpdbPendaftarEntity pendaftar) {
    final bloc = context.read<PpdbBloc>();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => PpdbPendaftarDetailPage(
              pendaftarId: pendaftar.id,
              namaAwal: pendaftar.namaLengkap,
            ),
          ),
        )
        .then((_) {
          // Aksi di halaman detail bisa mengubah status; muat ulang senyap.
          if (mounted) bloc.add(const PpdbMuatUlangSenyap());
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring PPDB'), centerTitle: true),
      body: BlocBuilder<PpdbBloc, PpdbState>(
        builder: (context, state) {
          if (state is PpdbForbidden) {
            return _NoAccessView(message: state.message);
          }
          if (state is PpdbError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<PpdbBloc>().add(
                const PpdbRefreshRequested(),
              ),
            );
          }
          if (state is! PpdbLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
              _StatusFilterBar(
                terpilih: state.filterStatus,
                onPilih: (status) => context.read<PpdbBloc>().add(
                  PpdbStatusFilterChanged(status),
                ),
              ),
              if (state.gelombangList.length > 1)
                _GelombangFilterBar(
                  gelombangList: state.gelombangList,
                  terpilih: state.filterGelombangId,
                  onPilih: (id) => context.read<PpdbBloc>().add(
                    PpdbGelombangFilterChanged(id),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<PpdbBloc>().add(const PpdbRefreshRequested());
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (!state.adaFilterAktif) ...[
                        SliverToBoxAdapter(
                          child: _RingkasanSection(statistik: state.statistik),
                        ),
                        if (state.gelombangAktif != null)
                          SliverToBoxAdapter(
                            child: _GelombangAktifCard(
                              gelombang: state.gelombangAktif!,
                            ),
                          ),
                      ],
                      SliverToBoxAdapter(
                        child: _JudulDaftar(
                          jumlah: state.pendaftarList.length,
                          adaFilter: state.adaFilterAktif,
                        ),
                      ),
                      if (state.sedangMemuatDaftar)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else if (state.pendaftarList.isEmpty)
                        SliverToBoxAdapter(
                          child: _EmptyView(
                            message: state.adaFilterAktif
                                ? 'Tidak ada pendaftar yang cocok dengan '
                                      'pencarian/filter.'
                                : 'Belum ada pendaftar PPDB.',
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _PendaftarCard(
                              pendaftar: state.pendaftarList[i],
                              onTap: () =>
                                  _bukaDetail(state.pendaftarList[i]),
                            ),
                            childCount: state.pendaftarList.length,
                          ),
                        ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Pencarian ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari nama / no pendaftaran / NISN / email',
          hintStyle: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
        style: const TextStyle(fontSize: 13.5),
      ),
    );
  }
}

// ── Filter status ─────────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final String? terpilih;
  final ValueChanged<String?> onPilih;

  const _StatusFilterBar({required this.terpilih, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.cardBg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: kPpdbStatusPendaftaran.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _ChipFilter(
              label: 'Semua',
              warna: AppColors.primary,
              aktif: terpilih == null,
              onTap: () => onPilih(null),
            );
          }
          final status = kPpdbStatusPendaftaran[i - 1];
          return _ChipFilter(
            label: labelStatusPendaftaran(status),
            warna: warnaStatusPendaftaran(status),
            aktif: terpilih == status,
            onTap: () => onPilih(terpilih == status ? null : status),
          );
        },
      ),
    );
  }
}

// ── Filter gelombang ──────────────────────────────────────────────────────────

class _GelombangFilterBar extends StatelessWidget {
  final List<PpdbGelombangEntity> gelombangList;
  final int? terpilih;
  final ValueChanged<int?> onPilih;

  const _GelombangFilterBar({
    required this.gelombangList,
    required this.terpilih,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppColors.cardBg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: gelombangList.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _ChipFilter(
              label: 'Semua Gelombang',
              warna: AppColors.secondary,
              aktif: terpilih == null,
              onTap: () => onPilih(null),
            );
          }
          final g = gelombangList[i - 1];
          return _ChipFilter(
            label: g.isActive ? '${g.namaGelombang} (aktif)' : g.namaGelombang,
            warna: AppColors.secondary,
            aktif: terpilih == g.id,
            onTap: () => onPilih(terpilih == g.id ? null : g.id),
          );
        },
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  final String label;
  final Color warna;
  final bool aktif;
  final VoidCallback onTap;

  const _ChipFilter({
    required this.label,
    required this.warna,
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
          color: aktif ? warna : warna.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: warna.withAlpha(aktif ? 255 : 80)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: aktif ? Colors.white : warna,
          ),
        ),
      ),
    );
  }
}

// ── Ringkasan statistik ───────────────────────────────────────────────────────

class _RingkasanSection extends StatelessWidget {
  final PpdbStatistikEntity statistik;

  const _RingkasanSection({required this.statistik});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _KartuAngka(
                  label: 'Total Pendaftar',
                  nilai: statistik.total,
                  warna: AppColors.primary,
                  ikon: Icons.groups_outlined,
                  besar: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KartuAngka(
                  label: 'Diterima',
                  nilai: statistik.diterima,
                  warna: AppColors.success,
                  ikon: Icons.check_circle_outline,
                  besar: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final status in const [
                'draft',
                'terverifikasi',
                'seleksi',
                'cadangan',
                'ditolak',
              ]) ...[
                Expanded(
                  child: _KartuAngka(
                    label: labelStatusPendaftaran(status),
                    nilai: statistik.jumlahUntuk(status),
                    warna: warnaStatusPendaftaran(status),
                    ikon: ikonStatusPendaftaran(status),
                  ),
                ),
                if (status != 'ditolak') const SizedBox(width: 6),
              ],
            ],
          ),
          if (!statistik.dariServer)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Statistik dihitung dari daftar yang termuat (maks. 200 '
                'pendaftar terbaru).',
                style: TextStyle(fontSize: 10.5, color: AppColors.textHint),
              ),
            ),
        ],
      ),
    );
  }
}

class _KartuAngka extends StatelessWidget {
  final String label;
  final int nilai;
  final Color warna;
  final IconData ikon;
  final bool besar;

  const _KartuAngka({
    required this.label,
    required this.nilai,
    required this.warna,
    required this.ikon,
    this.besar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: besar ? 12 : 6,
        vertical: besar ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: besar
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (besar)
            Row(
              children: [
                Icon(ikon, size: 16, color: warna),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Icon(ikon, size: 14, color: warna),
          SizedBox(height: besar ? 6 : 4),
          Text(
            '$nilai',
            style: TextStyle(
              fontSize: besar ? 22 : 14,
              fontWeight: FontWeight.bold,
              color: warna,
            ),
          ),
          if (!besar) ...[
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Gelombang aktif ───────────────────────────────────────────────────────────

class _GelombangAktifCard extends StatelessWidget {
  final PpdbGelombangEntity gelombang;

  const _GelombangAktifCard({required this.gelombang});

  @override
  Widget build(BuildContext context) {
    final periode =
        '${formatTanggalPpdb(gelombang.tglMulai)} - '
        '${formatTanggalPpdb(gelombang.tglSelesai)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(210)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Gelombang Aktif',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              if (gelombang.isActivePeriod == false)
                const PpdbStatusChip(
                  label: 'Di Luar Periode',
                  warna: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            gelombang.namaGelombang,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _BarisInfoGelombang(ikon: Icons.date_range_outlined, teks: periode),
          if (gelombang.kuotaTotal != null && gelombang.kuotaTotal! > 0)
            _BarisInfoGelombang(
              ikon: Icons.event_seat_outlined,
              teks: 'Kuota ${gelombang.kuotaTotal} siswa',
            ),
          if (gelombang.biayaPendaftaran != null)
            _BarisInfoGelombang(
              ikon: Icons.payments_outlined,
              teks:
                  'Biaya pendaftaran '
                  '${formatRupiah(gelombang.biayaPendaftaran)}',
            ),
          if (gelombang.metodeSeleksiLabel != null)
            _BarisInfoGelombang(
              ikon: Icons.rule_outlined,
              teks: 'Metode seleksi: ${gelombang.metodeSeleksiLabel}',
            ),
        ],
      ),
    );
  }
}

class _BarisInfoGelombang extends StatelessWidget {
  final IconData ikon;
  final String teks;

  const _BarisInfoGelombang({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(ikon, size: 13, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              teks,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Judul daftar ──────────────────────────────────────────────────────────────

class _JudulDaftar extends StatelessWidget {
  final int jumlah;
  final bool adaFilter;

  const _JudulDaftar({required this.jumlah, required this.adaFilter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          const Icon(
            Icons.list_alt_outlined,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Text(
            adaFilter ? 'Hasil Pencarian' : 'Daftar Pendaftar',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Text(
            '$jumlah pendaftar',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu pendaftar ───────────────────────────────────────────────────────────

class _PendaftarCard extends StatelessWidget {
  final PpdbPendaftarEntity pendaftar;
  final VoidCallback onTap;

  const _PendaftarCard({required this.pendaftar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatusPendaftaran(pendaftar.statusPendaftaran);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: warna.withAlpha(26),
                child: Icon(
                  pendaftar.jenisKelamin == 2
                      ? Icons.face_3_outlined
                      : Icons.face_outlined,
                  size: 22,
                  color: warna,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pendaftar.namaLengkap,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pendaftar.isSuspectFraud) ...[
                          const SizedBox(width: 4),
                          const Tooltip(
                            message: 'Terindikasi kecurangan',
                            child: Icon(
                              Icons.warning_amber_outlined,
                              size: 15,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pendaftar.noPendaftaran.isEmpty
                          ? '(tanpa nomor)'
                          : pendaftar.noPendaftaran,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (pendaftar.asalSekolah != null &&
                        pendaftar.asalSekolah!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 12,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pendaftar.asalSekolah!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        PpdbStatusChip(
                          label: labelStatusPendaftaran(
                            pendaftar.statusPendaftaran,
                          ),
                          warna: warna,
                          ikon: ikonStatusPendaftaran(
                            pendaftar.statusPendaftaran,
                          ),
                        ),
                        const Spacer(),
                        if (pendaftar.namaGelombang != null)
                          Flexible(
                            child: Text(
                              pendaftar.namaGelombang!,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textHint,
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_search_outlined,
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
