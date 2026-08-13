import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/ppdb_gelombang_entity.dart';
import '../bloc/ppdb_public_bloc.dart';
import '../widgets/ppdb_visuals.dart';

class PpdbPublicPage extends StatelessWidget {
  const PpdbPublicPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<PpdbPublicBloc>()..add(const PpdbPublicStarted()),
    child: const _PpdbPublicView(),
  );
}

class _PpdbPublicView extends StatefulWidget {
  const _PpdbPublicView();

  @override
  State<_PpdbPublicView> createState() => _PpdbPublicViewState();
}

class _PpdbPublicViewState extends State<_PpdbPublicView> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _nisn = TextEditingController();
  final _telepon = TextEditingController();
  final _asalSekolah = TextEditingController();
  final _nomor = TextEditingController();
  final Map<String, PlatformFile> _dokumen = {};
  int? _sekolahId;
  int? _gelombangId;
  String _jenisKelamin = 'L';

  static const _jenisDokumen = {
    'kartukeluarga': 'Kartu Keluarga',
    'akte': 'Akta Kelahiran',
    'rapor': 'Rapor',
    'ijazah': 'Ijazah',
  };

  @override
  void dispose() {
    for (final controller in [
      _nama,
      _email,
      _nisn,
      _telepon,
      _asalSekolah,
      _nomor,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pilihDokumen(String jenis) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: false,
    );
    if (!mounted || result == null) return;
    final file = result.files.single;
    if (file.path == null) {
      _pesan('File tidak dapat diakses dari perangkat ini.');
      return;
    }
    if (file.size > 2 * 1024 * 1024) {
      _pesan('Ukuran ${_jenisDokumen[jenis]} maksimal 2 MB.');
      return;
    }
    setState(() => _dokumen[jenis] = file);
  }

  Future<void> _daftar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sekolahId == null || _gelombangId == null) {
      _pesan('Pilih sekolah dan gelombang aktif.');
      return;
    }
    if (_dokumen.length != _jenisDokumen.length) {
      _pesan('Lengkapi empat dokumen wajib.');
      return;
    }

    final data = <String, dynamic>{
      'mst_sekolah_id': _sekolahId,
      'ppdb_gelombang_id': _gelombangId,
      'nama_lengkap': _nama.text.trim(),
      'email': _email.text.trim(),
      'jenis_kelamin': _jenisKelamin,
      if (_nisn.text.trim().isNotEmpty) 'nisn': _nisn.text.trim(),
      if (_telepon.text.trim().isNotEmpty) 'telp_hp': _telepon.text.trim(),
      if (_asalSekolah.text.trim().isNotEmpty)
        'asal_sekolah': _asalSekolah.text.trim(),
    };
    for (final entry in _dokumen.entries) {
      data[entry.key] = await MultipartFile.fromFile(
        entry.value.path!,
        filename: entry.value.name,
      );
    }
    if (!mounted) return;
    context.read<PpdbPublicBloc>().add(PpdbPublicDaftarRequested(data));
  }

  void _pesan(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Portal PPDB'), centerTitle: true),
    body: BlocConsumer<PpdbPublicBloc, PpdbPublicState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.pendaftaran != current.pendaftaran,
      listener: (context, state) {
        if (state.error != null) _pesan(state.error!);
        final hasil = state.pendaftaran;
        if (hasil != null) {
          _nomor.text = hasil.noPendaftaran;
          _pesan('Pendaftaran berhasil. Simpan ${hasil.noPendaftaran}.');
        }
      },
      builder: (context, state) => Stack(
        children: [
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const Material(
                  color: AppColors.cardBg,
                  child: TabBar(
                    tabs: [
                      Tab(text: 'Gelombang'),
                      Tab(text: 'Daftar'),
                      Tab(text: 'Cek Status'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _GelombangTab(
                        state: state,
                        sekolahId: _sekolahId,
                        onSekolahChanged: _ubahSekolah,
                      ),
                      _DaftarTab(
                        formKey: _formKey,
                        state: state,
                        sekolahId: _sekolahId,
                        gelombangId: _gelombangId,
                        jenisKelamin: _jenisKelamin,
                        nama: _nama,
                        email: _email,
                        nisn: _nisn,
                        telepon: _telepon,
                        asalSekolah: _asalSekolah,
                        dokumen: _dokumen,
                        jenisDokumen: _jenisDokumen,
                        onSekolahChanged: _ubahSekolah,
                        onGelombangChanged: (value) =>
                            setState(() => _gelombangId = value),
                        onJenisKelaminChanged: (value) =>
                            setState(() => _jenisKelamin = value),
                        onPilihDokumen: _pilihDokumen,
                        onDaftar: _daftar,
                      ),
                      _StatusTab(
                        nomor: _nomor,
                        state: state,
                        onCek: () {
                          final nomor = _nomor.text.trim();
                          if (nomor.isEmpty) {
                            _pesan('Nomor pendaftaran wajib diisi.');
                            return;
                          }
                          context.read<PpdbPublicBloc>().add(
                            PpdbPublicStatusRequested(nomor),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (state.loading)
            const ColoredBox(
              color: Color(0x22000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    ),
  );

  void _ubahSekolah(int? value) {
    setState(() {
      _sekolahId = value;
      _gelombangId = null;
    });
    if (value != null) {
      context.read<PpdbPublicBloc>().add(PpdbPublicSekolahChanged(value));
    }
  }
}

class _GelombangTab extends StatelessWidget {
  final PpdbPublicState state;
  final int? sekolahId;
  final ValueChanged<int?> onSekolahChanged;

  const _GelombangTab({
    required this.state,
    required this.sekolahId,
    required this.onSekolahChanged,
  });

  @override
  Widget build(BuildContext context) => _Content(
    children: [
      _SekolahDropdown(
        state: state,
        value: sekolahId,
        onChanged: onSekolahChanged,
      ),
      const SizedBox(height: 16),
      if (sekolahId == null)
        const _Info('Pilih sekolah untuk melihat gelombang aktif.')
      else if (state.gelombang.isEmpty && !state.loading)
        const _Info('Belum ada gelombang pendaftaran aktif.')
      else
        ...state.gelombang.map(_GelombangCard.new),
    ],
  );
}

class _DaftarTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final PpdbPublicState state;
  final int? sekolahId;
  final int? gelombangId;
  final String jenisKelamin;
  final TextEditingController nama;
  final TextEditingController email;
  final TextEditingController nisn;
  final TextEditingController telepon;
  final TextEditingController asalSekolah;
  final Map<String, PlatformFile> dokumen;
  final Map<String, String> jenisDokumen;
  final ValueChanged<int?> onSekolahChanged;
  final ValueChanged<int?> onGelombangChanged;
  final ValueChanged<String> onJenisKelaminChanged;
  final Future<void> Function(String) onPilihDokumen;
  final VoidCallback onDaftar;

  const _DaftarTab({
    required this.formKey,
    required this.state,
    required this.sekolahId,
    required this.gelombangId,
    required this.jenisKelamin,
    required this.nama,
    required this.email,
    required this.nisn,
    required this.telepon,
    required this.asalSekolah,
    required this.dokumen,
    required this.jenisDokumen,
    required this.onSekolahChanged,
    required this.onGelombangChanged,
    required this.onJenisKelaminChanged,
    required this.onPilihDokumen,
    required this.onDaftar,
  });

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: _Content(
      children: [
        _SekolahDropdown(
          state: state,
          value: sekolahId,
          onChanged: onSekolahChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: gelombangId,
          decoration: const InputDecoration(labelText: 'Gelombang aktif'),
          items: state.gelombang
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.namaGelombang),
                ),
              )
              .toList(),
          onChanged: onGelombangChanged,
          validator: (value) =>
              value == null ? 'Gelombang wajib dipilih' : null,
        ),
        const SizedBox(height: 12),
        _Field(controller: nama, label: 'Nama lengkap', required: true),
        _Field(
          controller: email,
          label: 'Email',
          required: true,
          keyboardType: TextInputType.emailAddress,
          validator: (value) =>
              value != null && value.contains('@') ? null : 'Email tidak valid',
        ),
        _Field(controller: nisn, label: 'NISN'),
        _Field(
          controller: telepon,
          label: 'Nomor telepon',
          keyboardType: TextInputType.phone,
        ),
        _Field(controller: asalSekolah, label: 'Asal sekolah'),
        DropdownButtonFormField<String>(
          initialValue: jenisKelamin,
          decoration: const InputDecoration(labelText: 'Jenis kelamin'),
          items: const [
            DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'P', child: Text('Perempuan')),
          ],
          onChanged: (value) {
            if (value != null) onJenisKelaminChanged(value);
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Dokumen wajib (PDF/JPG/PNG, maksimal 2 MB)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...jenisDokumen.entries.map(
          (entry) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              dokumen.containsKey(entry.key)
                  ? Icons.check_circle
                  : Icons.upload_file,
              color: dokumen.containsKey(entry.key)
                  ? AppColors.success
                  : AppColors.primary,
            ),
            title: Text(entry.value),
            subtitle: Text(dokumen[entry.key]?.name ?? 'Belum dipilih'),
            trailing: TextButton(
              onPressed: () => onPilihDokumen(entry.key),
              child: const Text('Pilih'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: state.loading ? null : onDaftar,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Kirim Pendaftaran'),
        ),
      ],
    ),
  );
}

class _StatusTab extends StatelessWidget {
  final TextEditingController nomor;
  final PpdbPublicState state;
  final VoidCallback onCek;

  const _StatusTab({
    required this.nomor,
    required this.state,
    required this.onCek,
  });

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    return _Content(
      children: [
        TextField(
          controller: nomor,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Nomor pendaftaran',
            hintText: 'PPDB-2026-001',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
          ),
          onSubmitted: (_) => onCek(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onCek, child: const Text('Cek Status')),
        if (status != null) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.namaLengkap,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(status.noPendaftaran),
                  const SizedBox(height: 12),
                  PpdbStatusChip(
                    label: labelStatusPendaftaran(status.status),
                    warna: warnaStatusPendaftaran(status.status),
                  ),
                  if (status.namaGelombang != null) ...[
                    const SizedBox(height: 8),
                    Text(status.namaGelombang!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Content extends StatelessWidget {
  final List<Widget> children;
  const _Content({required this.children});

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.lebarKontenMaks(context),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            20,
            padding.right,
            padding.bottom + 24,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _SekolahDropdown extends StatelessWidget {
  final PpdbPublicState state;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _SekolahDropdown({
    required this.state,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: value,
    decoration: const InputDecoration(labelText: 'Sekolah'),
    items: state.sekolah
        .map((item) => DropdownMenuItem(value: item.id, child: Text(item.nama)))
        .toList(),
    onChanged: onChanged,
    validator: (value) => value == null ? 'Sekolah wajib dipilih' : null,
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => required && (value == null || value.trim().isEmpty)
              ? '$label wajib diisi'
              : null,
    ),
  );
}

class _GelombangCard extends StatelessWidget {
  final PpdbGelombangEntity gelombang;
  const _GelombangCard(this.gelombang);

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: const Icon(Icons.campaign_outlined, color: AppColors.primary),
      title: Text(gelombang.namaGelombang),
      subtitle: Text(
        '${formatTanggalPpdb(gelombang.tglMulai)} - '
        '${formatTanggalPpdb(gelombang.tglSelesai)}',
      ),
      trailing: gelombang.biayaPendaftaran == null
          ? null
          : Text(formatRupiah(gelombang.biayaPendaftaran)),
    ),
  );
}

class _Info extends StatelessWidget {
  final String text;
  const _Info(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}
