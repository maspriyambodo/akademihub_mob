import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/rapor_entity.dart';

class RaporFormResult {
  final int? siswaId;
  final int? semester;
  final String? catatanWali;
  final int sakit;
  final int izin;
  final int tanpaKeterangan;

  const RaporFormResult({
    this.siswaId,
    this.semester,
    this.catatanWali,
    required this.sakit,
    required this.izin,
    required this.tanpaKeterangan,
  });
}

/// Uses IDs returned by the scoped rapor list; never accepts manual IDs.
class RaporFormPage extends StatefulWidget {
  final RaporEntity? awal;
  final List<RaporEntity> pilihan;

  const RaporFormPage({super.key, this.awal, required this.pilihan});

  @override
  State<RaporFormPage> createState() => _RaporFormPageState();
}

class _RaporFormPageState extends State<RaporFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _catatan;
  late final TextEditingController _sakit;
  late final TextEditingController _izin;
  late final TextEditingController _tanpaKeterangan;
  int? _siswaId;
  int? _semester;

  bool get _ubah => widget.awal != null;
  List<RaporEntity> get _siswa => widget.pilihan
      .where((r) => r.siswaId != null)
      .fold(
        <RaporEntity>[],
        (all, r) => all.any((x) => x.siswaId == r.siswaId) ? all : [...all, r],
      );
  List<RaporEntity> get _semesterPilihan => widget.pilihan
      .where((r) => int.tryParse(r.semesterKode ?? '') != null)
      .fold(
        <RaporEntity>[],
        (all, r) => all.any((x) => x.semesterKode == r.semesterKode)
            ? all
            : [...all, r],
      );

  @override
  void initState() {
    super.initState();
    final awal = widget.awal;
    _siswaId = awal?.siswaId;
    _semester = int.tryParse(awal?.semesterKode ?? '');
    _catatan = TextEditingController(text: awal?.catatanWali ?? '');
    _sakit = TextEditingController(text: '${awal?.sakit ?? 0}');
    _izin = TextEditingController(text: '${awal?.izin ?? 0}');
    _tanpaKeterangan = TextEditingController(
      text: '${awal?.tanpaKeterangan ?? 0}',
    );
  }

  @override
  void dispose() {
    _catatan.dispose();
    _sakit.dispose();
    _izin.dispose();
    _tanpaKeterangan.dispose();
    super.dispose();
  }

  int? _absen(TextEditingController c, String label) {
    final value = int.tryParse(c.text.trim());
    if (value == null || value < 0) return null;
    return value;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sakit = _absen(_sakit, 'Sakit');
    final izin = _absen(_izin, 'Izin');
    final tanpa = _absen(_tanpaKeterangan, 'Tanpa keterangan');
    if (sakit == null || izin == null || tanpa == null) return;
    Navigator.pop(
      context,
      RaporFormResult(
        siswaId: _siswaId,
        semester: _semester,
        catatanWali: _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
        sakit: sakit,
        izin: izin,
        tanpaKeterangan: tanpa,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);
    final selectorTersedia = _siswa.isNotEmpty && _semesterPilihan.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(_ubah ? 'Ubah Rapor' : 'Rapor Baru'),
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
                16,
                pad.right,
                32 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                if (!_ubah && !selectorTersedia)
                  const Text(
                    'Tidak ada siswa atau semester dalam data rapor yang dapat dipilih.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                if (!_ubah && selectorTersedia) ...[
                  DropdownButtonFormField<int>(
                    initialValue: _siswaId,
                    decoration: const InputDecoration(labelText: 'Siswa'),
                    items: [
                      for (final r in _siswa)
                        DropdownMenuItem(
                          value: r.siswaId,
                          child: Text(r.siswaNama ?? 'Siswa'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _siswaId = v),
                    validator: (v) => v == null ? 'Siswa wajib dipilih' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _semester,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: [
                      for (final r in _semesterPilihan)
                        DropdownMenuItem(
                          value: int.parse(r.semesterKode!),
                          child: Text(r.labelPeriode),
                        ),
                    ],
                    onChanged: (v) => setState(() => _semester = v),
                    validator: (v) =>
                        v == null ? 'Semester wajib dipilih' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _catatan,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Catatan wali kelas',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                for (final field in [
                  (controller: _sakit, label: 'Sakit'),
                  (controller: _izin, label: 'Izin'),
                  (controller: _tanpaKeterangan, label: 'Tanpa keterangan'),
                ]) ...[
                  TextFormField(
                    controller: field.controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: field.label),
                    validator: (v) =>
                        _absen(field.controller, field.label) == null
                        ? '${field.label} harus bilangan nol atau lebih'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton.icon(
                  onPressed: !_ubah && !selectorTersedia ? null : _submit,
                  icon: Icon(_ubah ? Icons.save_outlined : Icons.add),
                  label: Text(_ubah ? 'Simpan Perubahan' : 'Buat Rapor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
