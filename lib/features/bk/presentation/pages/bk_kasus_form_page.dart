import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/bk_siswa_ringkas_entity.dart';
import '../bloc/bk_form_bloc.dart';

/// Form pencatatan kasus BK baru (`POST /bk/kasus`, permission
/// `bk-kasus.create`).
///
/// - [guruIdAwal]: id guru dari `profile['id']` bila tersedia. Untuk role
///   `guru_bk` backend bisa mengirim profile null, sehingga form menampilkan
///   isian "ID Guru" manual sebagai cadangan.
/// - [bolehCariSiswa]: true bila user punya permission `siswa.view` — siswa
///   dipilih lewat pencarian `GET /siswa?search=`. Bila false, tersedia isian
///   ID siswa manual.
class BkKasusFormPage extends StatelessWidget {
  final int? guruIdAwal;
  final bool bolehCariSiswa;

  const BkKasusFormPage({
    super.key,
    this.guruIdAwal,
    required this.bolehCariSiswa,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BkFormBloc>()..add(const BkFormStarted()),
      child: _BkKasusFormView(
        guruIdAwal: guruIdAwal,
        bolehCariSiswa: bolehCariSiswa,
      ),
    );
  }
}

class _BkKasusFormView extends StatefulWidget {
  final int? guruIdAwal;
  final bool bolehCariSiswa;

  const _BkKasusFormView({
    required this.guruIdAwal,
    required this.bolehCariSiswa,
  });

  @override
  State<_BkKasusFormView> createState() => _BkKasusFormViewState();
}

class _BkKasusFormViewState extends State<_BkKasusFormView> {
  final _formKey = GlobalKey<FormState>();
  final _cariSiswaController = TextEditingController();
  final _siswaIdController = TextEditingController();
  final _guruIdController = TextEditingController();
  final _keteranganController = TextEditingController();

  BkSiswaRingkasEntity? _siswaTerpilih;
  int? _jenisId;
  DateTime _tanggal = DateTime.now();

  @override
  void dispose() {
    _cariSiswaController.dispose();
    _siswaIdController.dispose();
    _guruIdController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  String get _tanggalStr =>
      '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-'
      '${_tanggal.day.toString().padLeft(2, '0')}';

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (dipilih != null && mounted) {
      setState(() => _tanggal = dipilih);
    }
  }

  int? get _siswaIdFinal =>
      _siswaTerpilih?.id ?? int.tryParse(_siswaIdController.text.trim());

  int? get _guruIdFinal =>
      widget.guruIdAwal ?? int.tryParse(_guruIdController.text.trim());

  void _kirim() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final siswaId = _siswaIdFinal;
    final guruId = _guruIdFinal;
    final jenisId = _jenisId;
    if (siswaId == null || guruId == null || jenisId == null) return;

    context.read<BkFormBloc>().add(
      BkFormSubmitted(
        siswaId: siswaId,
        guruId: guruId,
        jenisId: jenisId,
        tanggal: _tanggalStr,
        keterangan: _keteranganController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kasus BK Baru'), centerTitle: true),
      body: BlocConsumer<BkFormBloc, BkFormState>(
        listenWhen: (_, s) =>
            s is BkFormSubmitSuccess || s is BkFormActionFailure,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is BkFormSubmitSuccess) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is BkFormActionFailure) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        buildWhen: (_, s) =>
            s is BkFormLoading || s is BkFormReady || s is BkFormError,
        builder: (context, state) {
          if (state is BkFormError) {
            return _FormErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<BkFormBloc>().add(const BkFormStarted()),
            );
          }
          if (state is! BkFormReady) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _JudulSeksi(teks: 'Siswa'),
                const SizedBox(height: 8),
                if (widget.bolehCariSiswa)
                  _PilihSiswaField(
                    controller: _cariSiswaController,
                    terpilih: _siswaTerpilih,
                    hasil: state.hasilCariSiswa,
                    sedangMencari: state.sedangCariSiswa,
                    onCari: (q) => context.read<BkFormBloc>().add(
                      BkFormSiswaSearchRequested(q),
                    ),
                    onPilih: (siswa) =>
                        setState(() => _siswaTerpilih = siswa),
                    onHapus: () => setState(() => _siswaTerpilih = null),
                  )
                else ...[
                  TextFormField(
                    controller: _siswaIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID Siswa',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                      helperText:
                          'Akun Anda tidak punya izin "siswa.view" untuk '
                          'mencari siswa — masukkan ID siswa secara manual.',
                      helperMaxLines: 3,
                    ),
                    style: const TextStyle(fontSize: 13.5),
                    validator: (v) =>
                        int.tryParse((v ?? '').trim()) == null
                        ? 'ID siswa wajib berupa angka'
                        : null,
                  ),
                ],
                if (widget.bolehCariSiswa && _siswaTerpilih == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Pilih siswa dari hasil pencarian.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _JudulSeksi(teks: 'Guru Pembimbing'),
                const SizedBox(height: 8),
                if (widget.guruIdAwal != null)
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 15,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Kasus akan dicatat atas nama Anda sebagai guru '
                          'pembimbing.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  TextFormField(
                    controller: _guruIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID Guru (mst_guru_id)',
                      prefixIcon: Icon(Icons.support_agent_outlined, size: 20),
                      helperText:
                          'Profil guru tidak tersedia dari sesi login — '
                          'masukkan ID guru pembimbing secara manual.',
                      helperMaxLines: 3,
                    ),
                    style: const TextStyle(fontSize: 13.5),
                    validator: (v) => int.tryParse((v ?? '').trim()) == null
                        ? 'ID guru wajib berupa angka'
                        : null,
                  ),
                const SizedBox(height: 20),
                _JudulSeksi(teks: 'Detail Kasus'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _jenisId,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kasus',
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  items: [
                    for (final jenis in state.jenisList)
                      DropdownMenuItem(
                        value: jenis.id,
                        child: Text(
                          jenis.kode != null
                              ? '${jenis.kode} — ${jenis.nama}'
                              : jenis.nama,
                          style: const TextStyle(fontSize: 13.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _jenisId = v),
                  validator: (v) => v == null ? 'Jenis kasus wajib dipilih' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pilihTanggal,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Kejadian',
                      prefixIcon: Icon(Icons.event_outlined, size: 20),
                    ),
                    child: Text(
                      _tanggalStr,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _keteranganController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan / Kronologi',
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(fontSize: 13.5),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Keterangan wajib diisi'
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: state.mengirim
                      ? null
                      : () {
                          if (widget.bolehCariSiswa &&
                              _siswaTerpilih == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pilih siswa terlebih dahulu'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          _kirim();
                        },
                  icon: state.mengirim
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    state.mengirim ? 'Menyimpan…' : 'Simpan Kasus',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Pemilih siswa (pencarian server-side) ────────────────────────────────────

class _PilihSiswaField extends StatelessWidget {
  final TextEditingController controller;
  final BkSiswaRingkasEntity? terpilih;
  final List<BkSiswaRingkasEntity> hasil;
  final bool sedangMencari;
  final ValueChanged<String> onCari;
  final ValueChanged<BkSiswaRingkasEntity> onPilih;
  final VoidCallback onHapus;

  const _PilihSiswaField({
    required this.controller,
    required this.terpilih,
    required this.hasil,
    required this.sedangMencari,
    required this.onCari,
    required this.onPilih,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final dipilih = terpilih;
    if (dipilih != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(90)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dipilih.nama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    [
                      if (dipilih.nis != null) 'NIS ${dipilih.nis}',
                      if (dipilih.namaKelas != null) dipilih.namaKelas!,
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onHapus,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          onChanged: onCari,
          decoration: InputDecoration(
            labelText: 'Cari Siswa (nama / NIS)',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: sedangMencari
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 13.5),
        ),
        if (hasil.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: hasil.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, i) {
                final siswa = hasil[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline, size: 20),
                  title: Text(
                    siswa.nama,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    [
                      if (siswa.nis != null) 'NIS ${siswa.nis}',
                      if (siswa.namaKelas != null) siswa.namaKelas!,
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  onTap: () => onPilih(siswa),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _JudulSeksi extends StatelessWidget {
  final String teks;

  const _JudulSeksi({required this.teks});

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}

// ── Error ────────────────────────────────────────────────────────────────────

class _FormErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FormErrorView({required this.message, required this.onRetry});

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
            const Text(
              'Gagal memuat master jenis kasus.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
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
