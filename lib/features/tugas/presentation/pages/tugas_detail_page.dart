import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/tugas_item_entity.dart';
import '../bloc/tugas_bloc.dart';
import '../widgets/tugas_widgets.dart';

/// Detail satu tugas untuk siswa/wali, lengkap dengan form pengumpulan.
///
/// Halaman ini memakai `TugasBloc` yang sama dengan daftar (di-pass lewat
/// `BlocProvider.value`) agar daftar ikut ter-update setelah mengumpulkan.
class TugasDetailPage extends StatefulWidget {
  final int tugasId;

  const TugasDetailPage({super.key, required this.tugasId});

  @override
  State<TugasDetailPage> createState() => _TugasDetailPageState();
}

class _TugasDetailPageState extends State<TugasDetailPage> {
  bool _submitting = false;

  Future<void> _bukaLampiran(String raw) async {
    final uri = Uri.tryParse(raw.trim());
    final messenger = ScaffoldMessenger.of(context);
    if (uri == null || !uri.hasScheme) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lampiran: $raw'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }
    final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!berhasil) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka lampiran'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _bukaFormKumpulkan(TugasItemEntity item) async {
    final hasil = await showModalBottomSheet<_HasilKumpulkan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KumpulkanSheet(
        judul: item.tugas.judul,
        jawabanAwal: item.pengumpulan?.jawaban,
        fileAwal: item.pengumpulan?.fileJawaban,
        sudahDikumpulkan: item.sudahDikumpulkan,
      ),
    );

    if (hasil == null || !mounted) return;

    setState(() => _submitting = true);
    context.read<TugasBloc>().add(
      TugasSubmitRequested(
        tugasId: item.tugas.id,
        jawaban: hasil.jawaban,
        fileJawaban: hasil.fileJawaban,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tugas'), centerTitle: true),
      body: BlocConsumer<TugasBloc, TugasState>(
        listenWhen: (_, current) =>
            current is TugasActionSuccess || current is TugasActionFailure,
        listener: (context, state) {
          if (!mounted) return;
          setState(() => _submitting = false);
          final messenger = ScaffoldMessenger.of(context);
          if (state is TugasActionSuccess) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is TugasActionFailure) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        buildWhen: (_, current) =>
            current is! TugasActionSuccess && current is! TugasActionFailure,
        builder: (context, state) {
          if (state is! TugasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final item = state.itemById(widget.tugasId);
          if (item == null) {
            return const _DetailEmptyView(message: 'Tugas tidak ditemukan');
          }

          return Stack(
            children: [
              _DetailBody(
                item: item,
                canSubmit: state.canSubmit,
                submitting: _submitting,
                onKumpulkan: () => _bukaFormKumpulkan(item),
                onBukaLampiran: _bukaLampiran,
              ),
              if (_submitting)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.ink.withValues(alpha: 0.2),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Isi detail ───────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final TugasItemEntity item;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onKumpulkan;
  final Future<void> Function(String) onBukaLampiran;

  const _DetailBody({
    required this.item,
    required this.canSubmit,
    required this.submitting,
    required this.onKumpulkan,
    required this.onBukaLampiran,
  });

  @override
  Widget build(BuildContext context) {
    final tugas = item.tugas;
    final pengumpulan = item.pengumpulan;
    final status = item.statusPengumpulan;
    final statusColor = statusPengumpulanColor(status);
    final deadline = tugas.tenggatWaktuDate;
    final deadlineColor = tugas.isLewatDeadline
        ? AppColors.error
        : (tugas.isMendekatiDeadline
              ? AppColors.warning
              : AppColors.textSecondary);

    final pad = Responsive.pagePadding(context);
    final cardPad = Responsive.isCompact(context) ? 12.0 : 16.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.lebarKontenMaks(context),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, 32),
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: EdgeInsets.all(cardPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            tugas.judul,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 17),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TugasBadge(
                          label: status.label,
                          color: statusColor,
                          maxWidth: 110,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.menu_book_outlined,
                      text: tugas.mapelLabel,
                    ),
                    if (tugas.guruNama != null)
                      _InfoRow(
                        icon: Icons.person_outline,
                        text: tugas.guruNama!,
                      ),
                    if (tugas.kelasNama != null)
                      _InfoRow(
                        icon: Icons.groups_outlined,
                        text: 'Kelas ${tugas.kelasNama}',
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: deadlineColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: deadlineColor.withAlpha(70)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tugas.isLewatDeadline
                                ? Icons.warning_amber_rounded
                                : Icons.schedule,
                            size: 16,
                            color: deadlineColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deadline == null
                                  ? 'Tanpa tenggat waktu'
                                  : 'Tenggat ${formatTanggalWaktu(deadline)}'
                                        ' · ${sisaWaktuLabel(deadline)}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: deadlineColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Deskripsi ─────────────────────────────────────────────────────
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Deskripsi',
              child: Text(
                (tugas.deskripsi == null || tugas.deskripsi!.isEmpty)
                    ? 'Tidak ada deskripsi'
                    : tugas.deskripsi!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // ── Lampiran guru ─────────────────────────────────────────────────
            if (tugas.fileLampiran != null &&
                tugas.fileLampiran!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Lampiran',
                child: InkWell(
                  onTap: () => onBukaLampiran(tugas.fileLampiran!),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tugas.fileLampiran!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Pengumpulan saya ──────────────────────────────────────────────
            if (pengumpulan != null && pengumpulan.sudahDikumpulkan) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Pengumpulan Saya',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TugasBadge(
                          label: pengumpulan.statusLabel ?? 'Dikumpulkan',
                          color: pengumpulan.isTerlambat
                              ? AppColors.error
                              : AppColors.info,
                        ),
                        Text(
                          formatTanggalWaktu(pengumpulan.waktuKumpulDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (pengumpulan.jawaban != null &&
                        pengumpulan.jawaban!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pengumpulan.jawaban!,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                    if (pengumpulan.fileJawaban != null &&
                        pengumpulan.fileJawaban!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => onBukaLampiran(pengumpulan.fileJawaban!),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.link,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pengumpulan.fileJawaban!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Penilaian ─────────────────────────────────────────────────────
            if (pengumpulan != null && pengumpulan.sudahDinilai) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Penilaian',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 140),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              pengumpulan.nilaiLabel,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 22),
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'Nilai tugas',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (pengumpulan.catatanGuru != null &&
                        pengumpulan.catatanGuru!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Catatan guru',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pengumpulan.catatanGuru!,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Tombol kumpulkan ──────────────────────────────────────────────
            if (canSubmit) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: submitting ? null : onKumpulkan,
                icon: const Icon(Icons.upload_outlined),
                label: Text(
                  item.sudahDikumpulkan
                      ? 'Perbarui Pengumpulan'
                      : 'Kumpulkan Tugas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tugas.isLewatDeadline) ...[
                const SizedBox(height: 8),
                const Text(
                  'Tenggat sudah lewat — pengumpulan akan ditandai terlambat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Form pengumpulan (bottom sheet) ──────────────────────────────────────────

class _HasilKumpulkan {
  final String? jawaban;
  final String? fileJawaban;
  const _HasilKumpulkan({this.jawaban, this.fileJawaban});
}

class _KumpulkanSheet extends StatefulWidget {
  final String judul;
  final String? jawabanAwal;
  final String? fileAwal;
  final bool sudahDikumpulkan;

  const _KumpulkanSheet({
    required this.judul,
    this.jawabanAwal,
    this.fileAwal,
    required this.sudahDikumpulkan,
  });

  @override
  State<_KumpulkanSheet> createState() => _KumpulkanSheetState();
}

class _KumpulkanSheetState extends State<_KumpulkanSheet> {
  late final TextEditingController _jawabanCtrl;
  late final TextEditingController _fileCtrl;
  final _formKey = GlobalKey<FormState>();
  String? _errorUmum;
  bool _mengunggah = false;

  @override
  void initState() {
    super.initState();
    _jawabanCtrl = TextEditingController(text: widget.jawabanAwal ?? '');
    _fileCtrl = TextEditingController(text: widget.fileAwal ?? '');
  }

  @override
  void dispose() {
    _jawabanCtrl.dispose();
    _fileCtrl.dispose();
    super.dispose();
  }

  void _kirim() {
    final jawaban = _jawabanCtrl.text.trim();
    final file = _fileCtrl.text.trim();

    if (jawaban.isEmpty && file.isEmpty) {
      setState(
        () => _errorUmum = 'Isi jawaban teks atau tautan lampiran minimal satu',
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      _HasilKumpulkan(
        jawaban: jawaban.isEmpty ? null : jawaban,
        fileJawaban: file.isEmpty ? null : file,
      ),
    );
  }

  Future<void> _pilihBerkas() async {
    final hasil = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: false,
    );
    if (hasil == null || !mounted) return;

    final berkas = hasil.files.single;
    final path = berkas.path;
    if (path == null) {
      setState(() => _errorUmum = 'Berkas tidak dapat dibaca dari perangkat');
      return;
    }
    if (berkas.size > 2 * 1024 * 1024) {
      setState(() => _errorUmum = 'Ukuran berkas maksimal 2 MB');
      return;
    }

    setState(() {
      _mengunggah = true;
      _errorUmum = null;
    });
    try {
      final response = await sl<ApiClient>().dio.post(
        '/files/upload',
        data: FormData.fromMap({
          'folder': 'tugas',
          'file': await MultipartFile.fromFile(path, filename: berkas.name),
        }),
      );
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final filePath = data is Map
          ? (data['path'] ?? data['file_path'] ?? data['url'])?.toString()
          : null;
      if (filePath == null || filePath.isEmpty) {
        throw const FormatException('Respons unggah tidak memuat path berkas');
      }
      if (!mounted) return;
      setState(() => _fileCtrl.text = filePath);
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      final message = body is Map ? body['message']?.toString() : null;
      setState(() => _errorUmum = message ?? 'Unggah berkas gagal');
    } on FileSystemException {
      if (mounted) {
        setState(() => _errorUmum = 'Berkas tidak dapat dibaca dari perangkat');
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorUmum = error.message);
    } finally {
      if (mounted) setState(() => _mengunggah = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hPad = Responsive.isCompact(context) ? 14.0 : 20.0;

    return Padding(
      // Sisakan ruang untuk keyboard supaya isi sheet tidak tertutup.
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          // Sadar keyboard: tinggi maksimum menyusut saat keyboard muncul.
          maxHeight: Responsive.tinggiSheet(context, rasio: 0.92),
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.sudahDikumpulkan
                      ? 'Perbarui Pengumpulan'
                      : 'Kumpulkan Tugas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _jawabanCtrl,
                  maxLines: 5,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban',
                    hintText: 'Tulis jawaban kamu di sini...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _mengunggah ? null : _pilihBerkas,
                  icon: _mengunggah
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file_outlined),
                  label: Text(_mengunggah ? 'Mengunggah...' : 'Pilih berkas'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                if (_fileCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Berkas siap dikirim',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ],
                if (_errorUmum != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorUmum!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text(
                          'Batal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _kirim,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text(
                          'Kirim',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget kecil ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Responsive.isCompact(context) ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailEmptyView extends StatelessWidget {
  final String message;
  const _DetailEmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: Responsive.pagePadding(context) + const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_late_outlined,
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
