import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/bk_hasil_entity.dart';
import '../../domain/entities/bk_kasus_entity.dart';
import '../../domain/entities/bk_sesi_entity.dart';
import '../../domain/entities/bk_tindakan_entity.dart';
import '../bloc/bk_detail_bloc.dart';
import '../widgets/bk_visuals.dart';

/// Detail kasus BK: info kasus + sesi konseling + hasil + tindak lanjut.
///
/// Data kasus dipakai dari entitas yang sudah dimuat di daftar (endpoint show
/// `/bk/kasus/{id}` tidak menambah field yang dibutuhkan); sesi/hasil/tindakan
/// dimuat lewat endpoint index masing-masing dengan filter `trx_bk_kasus_id`.
class BkDetailPage extends StatelessWidget {
  final BkKasusEntity kasus;
  final bool tampilkanNamaSiswa;
  final bool canViewSesi;
  final bool canViewHasil;
  final bool canViewTindakan;
  final bool canManageSesi;
  final bool canManageHasil;
  final bool canManageTindakan;

  const BkDetailPage({
    super.key,
    required this.kasus,
    required this.tampilkanNamaSiswa,
    required this.canViewSesi,
    required this.canViewHasil,
    required this.canViewTindakan,
    required this.canManageSesi,
    required this.canManageHasil,
    required this.canManageTindakan,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BkDetailBloc>()
        ..add(
          BkDetailLoadRequested(
            kasusId: kasus.id,
            canViewSesi: canViewSesi,
            canViewHasil: canViewHasil,
            canViewTindakan: canViewTindakan,
            canManageSesi: canManageSesi,
            canManageHasil: canManageHasil,
            canManageTindakan: canManageTindakan,
          ),
        ),
      child: _BkDetailView(
        kasus: kasus,
        tampilkanNamaSiswa: tampilkanNamaSiswa,
      ),
    );
  }
}

class _BkDetailView extends StatelessWidget {
  final BkKasusEntity kasus;
  final bool tampilkanNamaSiswa;

  const _BkDetailView({required this.kasus, required this.tampilkanNamaSiswa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kasus BK'), centerTitle: true),
      body: BlocConsumer<BkDetailBloc, BkDetailState>(
        listenWhen: (_, s) =>
            s is BkDetailActionSuccess || s is BkDetailActionFailure,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is BkDetailActionSuccess) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is BkDetailActionFailure) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        buildWhen: (_, s) =>
            s is BkDetailLoading || s is BkDetailLoaded || s is BkDetailError,
        builder: (context, state) {
          if (state is BkDetailError) {
            return _DetailErrorView(
              message: state.message,
              onRetry: () => context.read<BkDetailBloc>().add(
                const BkDetailRefreshRequested(),
              ),
            );
          }
          if (state is! BkDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final pad = context.pagePadding;
          return RefreshIndicator(
            onRefresh: () async => context.read<BkDetailBloc>().add(
              const BkDetailRefreshRequested(),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.lebarKontenMaks(context),
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    pad.left,
                    pad.top,
                    pad.right,
                    32,
                  ),
                  children: [
                    _KasusInfoCard(
                      kasus: kasus,
                      tampilkanNamaSiswa: tampilkanNamaSiswa,
                    ),
                    const SizedBox(height: 16),
                    _SeksiSesi(state: state),
                    const SizedBox(height: 16),
                    _SeksiHasil(state: state),
                    const SizedBox(height: 16),
                    _SeksiTindakan(state: state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Kartu info kasus ─────────────────────────────────────────────────────────

class _KasusInfoCard extends StatelessWidget {
  final BkKasusEntity kasus;
  final bool tampilkanNamaSiswa;

  const _KasusInfoCard({required this.kasus, required this.tampilkanNamaSiswa});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    kasus.judul ?? kasus.jenisNama ?? 'Kasus BK #${kasus.id}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BkStatusBadge(label: kasus.statusLabel),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            if (tampilkanNamaSiswa && kasus.siswaNama != null)
              _BarisInfo(
                ikon: Icons.person_outline,
                label: 'Siswa',
                nilai:
                    '${kasus.siswaNama}'
                    '${kasus.siswaNis != null ? ' (NIS ${kasus.siswaNis})' : ''}',
              ),
            _BarisInfo(
              ikon: Icons.category_outlined,
              label: 'Jenis Kasus',
              nilai: kasus.jenisNama ?? '-',
            ),
            _BarisInfo(
              ikon: Icons.support_agent_outlined,
              label: 'Guru Pembimbing',
              nilai: kasus.guruNama ?? '-',
            ),
            _BarisInfo(
              ikon: Icons.event_outlined,
              label: 'Tanggal',
              nilai: bkFormatTanggalDate(kasus.tanggalDate),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kronologi / Keterangan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (kasus.keterangan != null && kasus.keterangan!.isNotEmpty)
                  ? kasus.keterangan!
                  : 'Tidak ada keterangan yang dibagikan.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;

  const _BarisInfo({
    required this.ikon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 15, color: AppColors.textHint),
          const SizedBox(width: 8),
          SizedBox(
            width: context.isCompact ? 92 : 110,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

// ── Seksi sesi konseling ─────────────────────────────────────────────────────

class _SeksiSesi extends StatelessWidget {
  final BkDetailLoaded state;

  const _SeksiSesi({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SeksiCard(
      judul: 'Sesi Konseling',
      ikon: Icons.forum_outlined,
      warna: AppColors.primary,
      jumlah: state.canViewSesi ? state.sesi.length : null,
      tambahLabel: state.canManageSesi ? 'Tambah Sesi' : null,
      onTambah: state.canManageSesi
          ? () => _bukaFormSesi(context, context.read<BkDetailBloc>())
          : null,
      child: !state.canViewSesi
          ? const _CatatanIzin(
              pesan:
                  'Sesi konseling tidak ditampilkan karena akun Anda tidak '
                  'memiliki izin "bk-sesi.view".',
            )
          : state.errorSesi != null
          ? _SeksiError(pesan: state.errorSesi!)
          : state.sesi.isEmpty
          ? const _SeksiKosong(pesan: 'Belum ada sesi konseling.')
          : Column(
              children: [for (final sesi in state.sesi) _SesiTile(sesi: sesi)],
            ),
    );
  }

  Future<void> _bukaFormSesi(BuildContext context, BkDetailBloc bloc) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          BlocProvider.value(value: bloc, child: const _FormSesiSheet()),
    );
  }
}

class _SesiTile extends StatelessWidget {
  final BkSesiEntity sesi;

  const _SesiTile({required this.sesi});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                bkIkonMetode(sesi.metodeLabel),
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sesi.metodeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  bkFormatTanggal(sesi.tanggal ?? sesi.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (sesi.catatan != null && sesi.catatan!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sesi.catatan!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Seksi hasil ──────────────────────────────────────────────────────────────

class _SeksiHasil extends StatelessWidget {
  final BkDetailLoaded state;

  const _SeksiHasil({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SeksiCard(
      judul: 'Hasil Konseling',
      ikon: Icons.fact_check_outlined,
      warna: AppColors.success,
      jumlah: state.canViewHasil ? state.hasil.length : null,
      tambahLabel: state.canManageHasil ? 'Tambah Hasil' : null,
      onTambah: state.canManageHasil
          ? () => _bukaFormHasil(context, context.read<BkDetailBloc>())
          : null,
      child: !state.canViewHasil
          ? const _CatatanIzin(
              pesan:
                  'Hasil konseling tidak ditampilkan karena akun Anda tidak '
                  'memiliki izin "bk-hasil.view".',
            )
          : state.errorHasil != null
          ? _SeksiError(pesan: state.errorHasil!)
          : state.hasil.isEmpty
          ? const _SeksiKosong(pesan: 'Belum ada hasil konseling.')
          : Column(
              children: [
                for (final hasil in state.hasil) _HasilTile(hasil: hasil),
              ],
            ),
    );
  }

  Future<void> _bukaFormHasil(BuildContext context, BkDetailBloc bloc) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          BlocProvider.value(value: bloc, child: const _FormHasilSheet()),
    );
  }
}

class _HasilTile extends StatelessWidget {
  final BkHasilEntity hasil;

  const _HasilTile({required this.hasil});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 15,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Hasil',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  bkFormatTanggal(hasil.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasil.hasil ?? '-',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasil.rekomendasi != null && hasil.rekomendasi!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Rekomendasi',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hasil.rekomendasi!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Seksi tindak lanjut ──────────────────────────────────────────────────────

class _SeksiTindakan extends StatelessWidget {
  final BkDetailLoaded state;

  const _SeksiTindakan({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SeksiCard(
      judul: 'Tindak Lanjut',
      ikon: Icons.assignment_turned_in_outlined,
      warna: AppColors.warning,
      jumlah: state.canViewTindakan ? state.tindakan.length : null,
      tambahLabel: state.canManageTindakan ? 'Tambah Tindakan' : null,
      onTambah: state.canManageTindakan
          ? () => _bukaFormTindakan(context, context.read<BkDetailBloc>())
          : null,
      child: !state.canViewTindakan
          ? const _CatatanIzin(
              pesan:
                  'Tindak lanjut tidak ditampilkan karena akun Anda tidak '
                  'memiliki izin "bk-tindakan.view".',
            )
          : state.errorTindakan != null
          ? _SeksiError(pesan: state.errorTindakan!)
          : state.tindakan.isEmpty
          ? const _SeksiKosong(pesan: 'Belum ada tindak lanjut.')
          : Column(
              children: [
                for (final tindakan in state.tindakan)
                  _TindakanTile(tindakan: tindakan),
              ],
            ),
    );
  }

  Future<void> _bukaFormTindakan(
    BuildContext context,
    BkDetailBloc bloc,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          BlocProvider.value(value: bloc, child: const _FormTindakanSheet()),
    );
  }
}

class _TindakanTile extends StatelessWidget {
  final BkTindakanEntity tindakan;

  const _TindakanTile({required this.tindakan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right_alt, size: 17, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tindakan.deskripsi ?? '-',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            bkFormatTanggal(tindakan.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kerangka seksi ───────────────────────────────────────────────────────────

class _SeksiCard extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Color warna;
  final int? jumlah;
  final String? tambahLabel;
  final VoidCallback? onTambah;
  final Widget child;

  const _SeksiCard({
    required this.judul,
    required this.ikon,
    required this.warna,
    this.jumlah,
    this.tambahLabel,
    this.onTambah,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, size: 17, color: warna),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: warna,
                    ),
                  ),
                ),
                if (jumlah != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
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
                if (tambahLabel != null && onTambah != null)
                  Flexible(
                    child: TextButton.icon(
                      onPressed: onTambah,
                      style: TextButton.styleFrom(
                        foregroundColor: warna,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        tambahLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _SeksiKosong extends StatelessWidget {
  final String pesan;

  const _SeksiKosong({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        pesan,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}

class _SeksiError extends StatelessWidget {
  final String pesan;

  const _SeksiError({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 14, color: AppColors.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            pesan,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

class _CatatanIzin extends StatelessWidget {
  final String pesan;

  const _CatatanIzin({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            pesan,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }
}

// ── Bottom sheet: tambah sesi ────────────────────────────────────────────────

class _FormSesiSheet extends StatefulWidget {
  const _FormSesiSheet();

  @override
  State<_FormSesiSheet> createState() => _FormSesiSheetState();
}

class _FormSesiSheetState extends State<_FormSesiSheet> {
  final _formKey = GlobalKey<FormState>();
  final _catatanController = TextEditingController();
  DateTime _tanggal = DateTime.now();
  int _metode = 1;

  /// Ref `metode_bk` (diverifikasi dari `ReferenceSeeder`).
  static const Map<int, String> _metodeOpsi = {
    1: 'Tatap Muka',
    2: 'Online',
    3: 'Telepon',
  };

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (dipilih != null && mounted) {
      setState(() => _tanggal = dipilih);
    }
  }

  String get _tanggalStr =>
      '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-'
      '${_tanggal.day.toString().padLeft(2, '0')}';

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<BkDetailBloc>().add(
      BkSesiCreateRequested(
        tanggal: _tanggalStr,
        metode: _metode,
        catatan: _catatanController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Sesi Konseling',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pilihTanggal,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Sesi',
                    prefixIcon: Icon(Icons.event_outlined, size: 20),
                    isDense: true,
                  ),
                  child: Text(
                    bkFormatTanggalDate(_tanggal),
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _metode,
                decoration: const InputDecoration(
                  labelText: 'Metode',
                  prefixIcon: Icon(Icons.route_outlined, size: 20),
                  isDense: true,
                ),
                items: [
                  for (final entry in _metodeOpsi.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _metode = v ?? 1),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _catatanController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan Sesi',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 13.5),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Catatan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan Sesi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet: tambah hasil ───────────────────────────────────────────────

class _FormHasilSheet extends StatefulWidget {
  const _FormHasilSheet();

  @override
  State<_FormHasilSheet> createState() => _FormHasilSheetState();
}

class _FormHasilSheetState extends State<_FormHasilSheet> {
  final _formKey = GlobalKey<FormState>();
  final _hasilController = TextEditingController();
  final _rekomendasiController = TextEditingController();

  @override
  void dispose() {
    _hasilController.dispose();
    _rekomendasiController.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<BkDetailBloc>().add(
      BkHasilCreateRequested(
        hasil: _hasilController.text.trim(),
        rekomendasi: _rekomendasiController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Hasil Konseling',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hasilController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Hasil',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 13.5),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Hasil wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rekomendasiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rekomendasi',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 13.5),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Rekomendasi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan Hasil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet: tambah tindak lanjut ───────────────────────────────────────

class _FormTindakanSheet extends StatefulWidget {
  const _FormTindakanSheet();

  @override
  State<_FormTindakanSheet> createState() => _FormTindakanSheetState();
}

class _FormTindakanSheetState extends State<_FormTindakanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();

  @override
  void dispose() {
    _deskripsiController.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<BkDetailBloc>().add(
      BkTindakanCreateRequested(deskripsi: _deskripsiController.text.trim()),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Tindak Lanjut',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Tindakan',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 13.5),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan Tindakan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view (halaman penuh) ───────────────────────────────────────────────

class _DetailErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailErrorView({required this.message, required this.onRetry});

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
