import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/buku_entity.dart';
import 'perpustakaan_format.dart';

/// Hasil isian form peminjaman.
class HasilFormPinjam {
  final int siswaId;

  /// Format `YYYY-MM-DD`.
  final String tanggalPinjam;
  final String tanggalJatuhTempo;

  const HasilFormPinjam({
    required this.siswaId,
    required this.tanggalPinjam,
    required this.tanggalJatuhTempo,
  });
}

/// Bottom sheet pembuatan peminjaman.
///
/// Backend hanya menerima `mst_siswa_id` (integer), sehingga untuk petugas /
/// admin id siswa harus diketik manual — modul ini tidak boleh menambah
/// pemanggilan endpoint daftar siswa di luar folder perpustakaan.
/// Untuk role siswa, id diambil dari `profile['id']` dan dikunci.
Future<HasilFormPinjam?> tampilkanFormPinjam(
  BuildContext context, {
  required BukuEntity buku,
  int? defaultSiswaId,
  required bool kunciSiswa,
}) {
  return showModalBottomSheet<HasilFormPinjam>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FormPinjam(
      buku: buku,
      defaultSiswaId: defaultSiswaId,
      kunciSiswa: kunciSiswa,
    ),
  );
}

class _FormPinjam extends StatefulWidget {
  final BukuEntity buku;
  final int? defaultSiswaId;
  final bool kunciSiswa;

  const _FormPinjam({
    required this.buku,
    this.defaultSiswaId,
    required this.kunciSiswa,
  });

  @override
  State<_FormPinjam> createState() => _FormPinjamState();
}

class _FormPinjamState extends State<_FormPinjam> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _siswaController;

  late DateTime _jatuhTempo;

  @override
  void initState() {
    super.initState();
    _siswaController = TextEditingController(
      text: widget.defaultSiswaId?.toString() ?? '',
    );
    _jatuhTempo = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _siswaController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final besok = DateTime.now().add(const Duration(days: 1));
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _jatuhTempo,
      firstDate: DateTime(besok.year, besok.month, besok.day),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih tanggal jatuh tempo',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
    );
    if (dipilih != null) setState(() => _jatuhTempo = dipilih);
  }

  void _kirim() {
    if (!_formKey.currentState!.validate()) return;

    final siswaId = int.tryParse(_siswaController.text.trim());
    if (siswaId == null) return;

    Navigator.of(context).pop(
      HasilFormPinjam(
        siswaId: siswaId,
        tanggalPinjam: formatTanggalApi(DateTime.now()),
        tanggalJatuhTempo: formatTanggalApi(_jatuhTempo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    // Isi sheet digulir + padding bawah mengikuti tinggi keyboard supaya
    // tombol tetap terjangkau di layar pendek.
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: pad.left + 4,
        right: pad.right + 4,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
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
            const SizedBox(height: 16),
            Text(
              'Buat Peminjaman',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.buku.judul,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'ID Siswa',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _siswaController,
              readOnly: widget.kunciSiswa,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Masukkan ID siswa',
                isDense: true,
                fillColor: widget.kunciSiswa ? AppColors.surface : Colors.white,
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              ),
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'ID siswa wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Tanggal Jatuh Tempo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pilihTanggal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formatTanggalDate(_jatuhTempo),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tanggal pinjam otomatis diisi hari ini.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _kirim,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: const Text('Lanjut'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
