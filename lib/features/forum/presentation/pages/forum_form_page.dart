import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/forum_entity.dart';
import '../widgets/forum_visuals.dart';

/// Hasil isian form topik forum.
class ForumFormResult {
  final String judul;
  final String konten;
  final int tipe;
  final bool isAnonymous;

  const ForumFormResult({
    required this.judul,
    required this.konten,
    required this.tipe,
    required this.isAnonymous,
  });
}

/// Halaman form buat/ubah topik. Sengaja "bodoh": hanya mengumpulkan input dan
/// mengembalikan [ForumFormResult] lewat `Navigator.pop`. Pemanggil yang
/// mengirimkannya ke `ForumBloc`.
class ForumFormPage extends StatefulWidget {
  /// null = mode buat baru; terisi = mode ubah.
  final ForumEntity? awal;

  const ForumFormPage({super.key, this.awal});

  @override
  State<ForumFormPage> createState() => _ForumFormPageState();
}

class _ForumFormPageState extends State<ForumFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulC;
  late final TextEditingController _kontenC;
  late int _tipe;
  late bool _anonim;

  bool get _modeUbah => widget.awal != null;

  @override
  void initState() {
    super.initState();
    final awal = widget.awal;
    _judulC = TextEditingController(text: awal?.judul ?? '');
    _kontenC = TextEditingController(text: awal?.konten ?? '');
    _tipe = awal?.tipe ?? 1;
    _anonim = awal?.isAnonymous ?? false;
  }

  @override
  void dispose() {
    _judulC.dispose();
    _kontenC.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ForumFormResult(
        judul: _judulC.text.trim(),
        konten: _kontenC.text.trim(),
        tipe: _tipe,
        isAnonymous: _anonim,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);
    // Ruang ekstra di bawah supaya tombol kirim tetap dapat digulir ke atas
    // keyboard saat sedang mengetik.
    final bawahKeyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(_modeUbah ? 'Ubah Topik' : 'Topik Baru'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.lebarKontenMaks(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                pad.left,
                pad.top,
                pad.right,
                32 + bawahKeyboard,
              ),
              children: [
                const Text(
                  'Judul',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _judulC,
                  // Backend membatasi `judul` maksimal 200 karakter.
                  maxLength: 200,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText:
                        'Ringkas dan jelas, mis. "Soal nomor 5 halaman 42"',
                  ),
                  validator: (v) {
                    final teks = (v ?? '').trim();
                    if (teks.isEmpty) return 'Judul wajib diisi';
                    if (teks.length > 200) return 'Judul maksimal 200 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 4),

                const Text(
                  'Isi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _kontenC,
                  // Layar sempit: kotak isi dibuat lebih pendek agar tombol kirim
                  // tetap mudah dijangkau.
                  minLines: Responsive.isCompact(context) ? 4 : 6,
                  maxLines: 14,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Tulis pertanyaan atau bahan diskusi di sini…',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Isi topik wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Tipe Topik',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: forumTipeOptions.map((t) {
                    final terpilih = t.nilai == _tipe;
                    return ChoiceChip(
                      selected: terpilih,
                      onSelected: (_) => setState(() => _tipe = t.nilai),
                      avatar: Icon(
                        t.icon,
                        size: 16,
                        color: terpilih ? Colors.white : t.color,
                      ),
                      label: Text(t.label),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: terpilih
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      selectedColor: t.color,
                      backgroundColor: AppColors.surface,
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                SwitchListTile.adaptive(
                  value: _anonim,
                  onChanged: (v) => setState(() => _anonim = v),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Kirim sebagai anonim',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Nama Anda disembunyikan dari pengguna lain',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _simpan,
                  icon: Icon(_modeUbah ? Icons.save_outlined : Icons.send),
                  label: Text(_modeUbah ? 'Simpan Perubahan' : 'Kirim Topik'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
