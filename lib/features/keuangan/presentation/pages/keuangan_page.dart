import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/pembayaran_spp_entity.dart';
import '../../domain/entities/tunggakan_entity.dart';
import '../bloc/keuangan_aksi_status.dart';
import '../bloc/keuangan_bloc.dart';
import '../widgets/keuangan_format.dart';
import 'keuangan_detail_page.dart';

class KeuanganPage extends StatelessWidget {
  const KeuanganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<KeuanganBloc>(),
      child: const _KeuanganView(),
    );
  }
}

class _KeuanganView extends StatefulWidget {
  const _KeuanganView();

  @override
  State<_KeuanganView> createState() => _KeuanganViewState();
}

class _KeuanganViewState extends State<_KeuanganView>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  Timer? _pollTimer;
  int _pollCount = 0;

  String _role = '';
  bool _canBayar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final role = (user.role ?? 'admin').toLowerCase();
      final profileId = _keId(user.profile?['id']);

      // Untuk siswa, id kelas ada di `profile['kelas']['id']`
      // (fallback `mst_kelas_id` / `kelas_id`). Dipakai untuk mencari
      // tarif SPP lewat `GET /keuangan/tarif-spp/kelas/{kelasId}`.
      final profile = user.profile;
      int? kelasId;
      if (profile != null) {
        final kelas = profile['kelas'];
        if (kelas is Map) kelasId = _keId(kelas['id']);
        kelasId ??= _keId(profile['mst_kelas_id']);
        kelasId ??= _keId(profile['kelas_id']);
      }

      setState(() {
        _role = role;
        _canBayar = user.hasPermission('pembayaran-spp.bayar');
      });

      context.read<KeuanganBloc>().add(
        KeuanganLoadRequested(
          role: role,
          profileId: profileId,
          kelasId: kelasId,
        ),
      );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _mulaiRekonsiliasi();
    }
  }

  void _mulaiRekonsiliasi() {
    _pollTimer?.cancel();
    _pollCount = 0;

    if (!mounted) return;
    context.read<KeuanganBloc>().add(const KeuanganRefreshRequested());

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _pollCount++;
      if (_pollCount >= 3) {
        timer.cancel();
        return;
      }

      context.read<KeuanganBloc>().add(const KeuanganRefreshRequested());
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<KeuanganBloc>().add(KeuanganSearchChanged(value));
    });
  }

  /// Ambil id numerik dari nilai yang bisa berupa int maupun String.
  static int? _keId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  /// Mode pribadi untuk siswa & wali. Kode role `WALI_SISWA` mengandung
  /// substring "siswa", jadi `wali` selalu dicek lebih dulu — di sini keduanya
  /// menghasilkan tampilan yang sama sehingga cukup satu pemeriksaan gabungan.
  bool get _modePribadi => _role.contains('wali') || _role.contains('siswa');

  void _bukaDetail(PembayaranSppEntity item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KeuanganDetailPage(
          pembayaran: item,
          canBayar: _canBayar,
          modeAdmin: !_modePribadi,
        ),
      ),
    );
  }

  Future<void> _bukaCheckout(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _pesan('Tautan pembayaran tidak valid', gagal: true);
      return;
    }
    final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!berhasil) {
      _pesan(
        'Tidak dapat membuka halaman pembayaran. Salin tautan berikut:\n$url',
        gagal: true,
      );
    }
  }

  void _pesan(String teks, {bool gagal = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
        backgroundColor: gagal ? AppColors.error : AppColors.success,
        duration: Duration(seconds: gagal ? 6 : 3),
      ),
    );
  }

  Future<void> _konfirmasiLunasiSemua(List<int> bulan, int tahun) async {
    final bloc = context.read<KeuanganBloc>();
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lunasi Semua Tunggakan'),
        content: Text(
          'Catat ${bulan.length} bulan tunggakan tahun $tahun sebagai LUNAS '
          '(metode Tunai)?\n\nAksi ini tidak dapat dibatalkan dari aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lunasi'),
          ),
        ],
      ),
    );

    if (setuju == true) {
      bloc.add(KeuanganBayarMultipleRequested(bulan: bulan, tahun: tahun));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tampilkanPencarian = _role.isNotEmpty && !_modePribadi;

    return Scaffold(
      appBar: AppBar(title: const Text('Keuangan / SPP'), centerTitle: true),
      body: Column(
        children: [
          if (tampilkanPencarian)
            _SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          Expanded(
            child: BlocConsumer<KeuanganBloc, KeuanganState>(
              listenWhen: (prev, curr) =>
                  curr is KeuanganLoaded &&
                  (prev is! KeuanganLoaded ||
                      prev.aksiStatus != curr.aksiStatus),
              listener: (context, state) {
                if (state is! KeuanganLoaded) return;
                if (state.aksiStatus == KeuanganAksiStatus.success) {
                  final url = state.aksiUrl;
                  if (url != null && url.isNotEmpty) {
                    _bukaCheckout(url);
                  } else {
                    _pesan(state.aksiMessage ?? 'Aksi berhasil');
                  }
                } else if (state.aksiStatus == KeuanganAksiStatus.failure) {
                  _pesan(
                    state.aksiMessage ?? 'Aksi gagal diproses',
                    gagal: true,
                  );
                }
              },
              builder: (context, state) {
                if (state is KeuanganInitial || state is KeuanganLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is KeuanganError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context.read<KeuanganBloc>().add(
                      const KeuanganRefreshRequested(),
                    ),
                  );
                }
                if (state is KeuanganLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<KeuanganBloc>().add(
                        const KeuanganRefreshRequested(),
                      );
                    },
                    child: state.modePribadi
                        ? _TampilanPribadi(
                            state: state,
                            canBayar: _canBayar,
                            onDetail: _bukaDetail,
                            onBayarOnline: (bulan, tahun) =>
                                context.read<KeuanganBloc>().add(
                                  KeuanganBayarOnlineRequested(
                                    bulan: bulan,
                                    tahun: tahun,
                                  ),
                                ),
                            onLunasiSemua: () => _konfirmasiLunasiSemua(
                              state.bulanMenunggak,
                              state.tahun,
                            ),
                            onGantiTahun: (tahun) => context
                                .read<KeuanganBloc>()
                                .add(KeuanganTahunChanged(tahun)),
                          )
                        : _TampilanDaftar(state: state, onDetail: _bukaDetail),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tampilan siswa / wali ────────────────────────────────────────────────────

class _TampilanPribadi extends StatelessWidget {
  final KeuanganLoaded state;
  final bool canBayar;
  final void Function(PembayaranSppEntity) onDetail;
  final void Function(int bulan, int tahun) onBayarOnline;
  final VoidCallback onLunasiSemua;
  final ValueChanged<int> onGantiTahun;

  const _TampilanPribadi({
    required this.state,
    required this.canBayar,
    required this.onDetail,
    required this.onBayarOnline,
    required this.onLunasiSemua,
    required this.onGantiTahun,
  });

  @override
  Widget build(BuildContext context) {
    final riwayat = state.pembayaran;
    final tunggakan = state.tunggakan;
    final sedangProses = state.aksiStatus == KeuanganAksiStatus.loading;
    final pad = Responsive.pagePadding(context);

    // Di tablet lebar konten dibatasi supaya baris tidak melebar tak terbaca.
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.lebarKontenMaks(context),
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 32),
          children: [
            _KartuRingkasan(state: state),
            const SizedBox(height: 12),
            _TahunSelector(tahun: state.tahun, onGanti: onGantiTahun),
            if (state.catatan != null) ...[
              const SizedBox(height: 12),
              _Catatan(pesan: state.catatan!),
            ],

            // ── Tunggakan ──────────────────────────────────────────────────
            if (tunggakan.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: _JudulSeksi(
                      judul: 'Tunggakan',
                      ikon: Icons.warning_amber_rounded,
                      warna: AppColors.error,
                    ),
                  ),
                  if (canBayar && state.bulanMenunggak.isNotEmpty)
                    Flexible(
                      child: TextButton.icon(
                        onPressed: sedangProses ? null : onLunasiSemua,
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text(
                          'Lunasi semua',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ...tunggakan.map(
                (t) => _KartuTunggakan(
                  tunggakan: t,
                  canBayar: canBayar,
                  sedangProses: sedangProses,
                  onBayar: () => onBayarOnline(t.bulan, t.tahun),
                ),
              ),
            ],

            // ── Riwayat / tagihan tercatat ─────────────────────────────────
            const SizedBox(height: 20),
            const _JudulSeksi(
              judul: 'Riwayat & Tagihan',
              ikon: Icons.receipt_long_outlined,
              warna: AppColors.primary,
            ),
            const SizedBox(height: 8),
            if (riwayat.isEmpty)
              const _EmptyView(
                message: 'Belum ada catatan pembayaran SPP untuk akun ini',
              )
            else
              ...riwayat.map(
                (p) => _KartuPembayaran(
                  pembayaran: p,
                  tampilkanSiswa: false,
                  onTap: () => onDetail(p),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tampilan admin / guru ────────────────────────────────────────────────────

class _TampilanDaftar extends StatelessWidget {
  final KeuanganLoaded state;
  final void Function(PembayaranSppEntity) onDetail;

  const _TampilanDaftar({required this.state, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    final items = state.pembayaran;
    final pad = Responsive.pagePadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.lebarKontenMaks(context),
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 32),
          children: [
            if (state.laporan != null) _KartuLaporan(state: state),
            if (state.laporan != null) const SizedBox(height: 16),
            if (items.isEmpty)
              _EmptyView(
                message: state.search.trim().isNotEmpty
                    ? 'Tidak ada pembayaran yang cocok dengan pencarian'
                    : 'Belum ada data pembayaran SPP',
              )
            else
              ...items.map(
                (p) => _KartuPembayaran(
                  pembayaran: p,
                  tampilkanSiswa: true,
                  onTap: () => onDetail(p),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Kartu ringkasan (siswa/wali) ─────────────────────────────────────────────

class _KartuRingkasan extends StatelessWidget {
  final KeuanganLoaded state;

  const _KartuRingkasan({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.totalTunggakan;
    final adaTunggakan = total > 0;
    final warna = adaTunggakan ? AppColors.error : AppColors.success;

    final now = DateTime.now();
    final tagihanBulanIni = state.tagihanBulanIni;
    final tunggakanBulanIni = state.tunggakanBulanIni;

    final String labelStatusBulanIni;
    final Color warnaStatusBulanIni;
    final IconData ikonBulanIni;

    if (tagihanBulanIni != null) {
      labelStatusBulanIni = tagihanBulanIni.statusLabel;
      warnaStatusBulanIni = warnaStatus(tagihanBulanIni.statusKey);
      ikonBulanIni = ikonStatus(tagihanBulanIni.statusKey);
    } else if (tunggakanBulanIni != null) {
      labelStatusBulanIni = 'Belum Lunas';
      warnaStatusBulanIni = AppColors.error;
      ikonBulanIni = Icons.error_outline;
    } else if (state.status?.sudahLunasBulan(now.month) == true) {
      labelStatusBulanIni = 'Lunas';
      warnaStatusBulanIni = AppColors.success;
      ikonBulanIni = Icons.check_circle;
    } else {
      labelStatusBulanIni = 'Belum ada tagihan';
      warnaStatusBulanIni = AppColors.textSecondary;
      ikonBulanIni = Icons.schedule;
    }

    final status = state.status;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: warna.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    adaTunggakan
                        ? Icons.account_balance_wallet
                        : Icons.verified_outlined,
                    color: warna,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Tunggakan',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Nominal bisa panjang ("Rp 14.000.000") — dikecilkan
                      // otomatis agar selalu muat satu baris.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          adaTunggakan ? formatRupiah(total) : 'Tidak ada',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(
                              context,
                              adaTunggakan ? 26 : 20,
                            ),
                            fontWeight: FontWeight.bold,
                            color: warna,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (adaTunggakan) ...[
              const SizedBox(height: 8),
              Text(
                '${state.tunggakan.length} bulan menunggak'
                '${state.totalDenda > 0 ? ' · denda ${formatRupiah(state.totalDenda)}' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Divider(height: 24, color: AppColors.divider),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status ${namaBulan(now.month)} ${now.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(
                        label: labelStatusBulanIni,
                        color: warnaStatusBulanIni,
                        icon: ikonBulanIni,
                        besar: true,
                      ),
                    ],
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Bulan lunas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${status.lunas}/${status.totalBulan}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 18),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: status.progres,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tahun ajaran ${status.tahunAjaran ?? '-'}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Kartu laporan periode (admin) ────────────────────────────────────────────

class _KartuLaporan extends StatelessWidget {
  final KeuanganLoaded state;

  const _KartuLaporan({required this.state});

  @override
  Widget build(BuildContext context) {
    final laporan = state.laporan!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Laporan ${laporan.namaBulanDari ?? namaBulan(laporan.bulanDari)}'
                    ' – ${laporan.namaBulanSampai ?? namaBulan(laporan.bulanSampai)}'
                    ' ${laporan.tahun}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.divider),
            _BarisMetrik(
              metrik: [
                _Metrik(
                  label: 'Pendapatan',
                  nilai: formatRupiah(laporan.totalPendapatan),
                  warna: AppColors.success,
                ),
                _Metrik(
                  label: 'Transaksi',
                  nilai: '${laporan.totalTransaksi}',
                  warna: AppColors.info,
                ),
                _Metrik(
                  label: 'Rata-rata/bln',
                  nilai: formatRupiah(laporan.rataRataPerBulan),
                  warna: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiga metrik berdampingan di layar normal, ditumpuk vertikal di layar
/// sempit supaya nominal rupiah panjang tidak tergencet.
class _BarisMetrik extends StatelessWidget {
  final List<Widget> metrik;

  const _BarisMetrik({required this.metrik});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isCompact(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < metrik.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            metrik[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final m in metrik) Expanded(child: m)],
    );
  }
}

class _Metrik extends StatelessWidget {
  final String label;
  final String nilai;
  final Color warna;

  const _Metrik({
    required this.label,
    required this.nilai,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            nilai,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: warna,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Kartu tunggakan ──────────────────────────────────────────────────────────

class _KartuTunggakan extends StatelessWidget {
  final TunggakanEntity tunggakan;
  final bool canBayar;
  final bool sedangProses;
  final VoidCallback onBayar;

  const _KartuTunggakan({
    required this.tunggakan,
    required this.canBayar,
    required this.sedangProses,
    required this.onBayar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withAlpha(70)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    namaBulanSingkat(tunggakan.bulan),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${namaBulan(tunggakan.bulan)} ${tunggakan.tahun}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SPP ${formatRupiah(tunggakan.nominal)}'
                        '${tunggakan.adaDenda ? ' + denda ${formatRupiah(tunggakan.denda)}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Nominal total wajib muat satu baris.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatRupiah(tunggakan.total),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      if (tunggakan.bulanTerlambat > 0)
                        Text(
                          'telat ${tunggakan.bulanTerlambat} bln'
                          ' (${formatPersen(tunggakan.dendaPersen)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (canBayar) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: sedangProses ? null : onBayar,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Bayar Online'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Kartu pembayaran ─────────────────────────────────────────────────────────

class _KartuPembayaran extends StatelessWidget {
  final PembayaranSppEntity pembayaran;
  final bool tampilkanSiswa;
  final VoidCallback onTap;

  const _KartuPembayaran({
    required this.pembayaran,
    required this.tampilkanSiswa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatus(pembayaran.statusKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: warna.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: warna.withAlpha(70)),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      namaBulanSingkat(pembayaran.bulan),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: warna,
                      ),
                    ),
                    Text(
                      '${pembayaran.tahun ?? ''}',
                      style: TextStyle(fontSize: 9, color: warna),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tampilkanSiswa) ...[
                      Text(
                        pembayaran.siswaNama ?? 'Siswa',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pembayaran.labelPeriode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else
                      Text(
                        pembayaran.labelPeriode,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRupiah(pembayaran.nominalEfektif),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusBadge(
                          label: pembayaran.statusLabel,
                          color: warna,
                          icon: ikonStatus(pembayaran.statusKey),
                        ),
                        if (pembayaran.isLunas &&
                            pembayaran.tanggalBayar != null)
                          InfoChip(
                            icon: Icons.event_available_outlined,
                            label: formatTanggal(pembayaran.tanggalBayar),
                            color: AppColors.success,
                          ),
                        if (pembayaran.metodePembayaran != null &&
                            pembayaran.metodePembayaran!.isNotEmpty)
                          InfoChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: pembayaran.metodePembayaran!,
                            color: AppColors.primary,
                          ),
                        if (tampilkanSiswa && pembayaran.kelasNama != null)
                          InfoChip(
                            icon: Icons.class_outlined,
                            label: pembayaran.kelasNama!,
                            color: AppColors.info,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Komponen kecil ───────────────────────────────────────────────────────────

class _JudulSeksi extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Color warna;

  const _JudulSeksi({
    required this.judul,
    required this.ikon,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 18, color: warna),
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
      ],
    );
  }
}

class _TahunSelector extends StatelessWidget {
  final int tahun;
  final ValueChanged<int> onGanti;

  const _TahunSelector({required this.tahun, required this.onGanti});

  @override
  Widget build(BuildContext context) {
    final tahunSekarang = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            color: AppColors.primary,
            onPressed: () => onGanti(tahun - 1),
            tooltip: 'Tahun sebelumnya',
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tahun $tahun',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'periode tunggakan & status',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            color: tahun >= tahunSekarang + 1
                ? AppColors.textHint
                : AppColors.primary,
            onPressed: tahun >= tahunSekarang + 1
                ? null
                : () => onGanti(tahun + 1),
            tooltip: 'Tahun berikutnya',
          ),
        ],
      ),
    );
  }
}

class _Catatan extends StatelessWidget {
  final String pesan;
  const _Catatan({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pesan,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(pad.left, 8, pad.right, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari nama atau NIS siswa...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, child) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClear,
                  ),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
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
    // Dibungkus scroll view supaya tetap terbaca di layar pendek / saat
    // pengguna memperbesar font sistem.
    return Center(
      child: SingleChildScrollView(
        padding: Responsive.pagePadding(context) * 2,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
