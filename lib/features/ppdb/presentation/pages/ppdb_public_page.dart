import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/ppdb_public_api.dart';

class PpdbPublicPage extends StatefulWidget {
  final Dio dio;
  final Future<PlatformFile?> Function()? pickFile;

  const PpdbPublicPage({super.key, required this.dio, this.pickFile});

  @override
  State<PpdbPublicPage> createState() => _PpdbPublicPageState();
}

class _PpdbPublicPageState extends State<PpdbPublicPage> {
  late final PpdbPublicApi _api;
  final _number = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nisn = TextEditingController();
  final _phone = TextEditingController();
  final _originSchool = TextEditingController();
  List<Map<String, dynamic>> _schools = const [];
  List<Map<String, dynamic>> _waves = const [];
  Map<String, dynamic>? _status;
  int? _schoolId;
  int? _waveId;
  String? _gender;
  final Map<String, PlatformFile> _documents = {};
  Map<String, dynamic>? _registration;
  String? _error;
  bool _loading = true;
  bool _checking = false;
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _api = PpdbPublicApi(widget.dio);
    _loadSchools();
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _nisn.dispose();
    _phone.dispose();
    _originSchool.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    try {
      final schools = await _api.schools();
      if (mounted) setState(() => _schools = schools);
    } on DioException {
      if (mounted)
        setState(() => _error = 'Daftar sekolah tidak dapat dimuat.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectSchool(int? id) async {
    setState(() {
      _schoolId = id;
      _waveId = null;
      _waves = const [];
      _error = null;
    });
    if (id == null) return;
    try {
      final waves = await _api.activeWaves(id);
      if (mounted) setState(() => _waves = waves);
    } on DioException {
      if (mounted)
        setState(() => _error = 'Gelombang aktif tidak dapat dimuat.');
    }
  }

  Future<PlatformFile?> _pickFile() =>
      widget.pickFile?.call() ??
      FilePicker.platform
          .pickFiles(withData: true)
          .then((result) => result?.files.single);

  Future<void> _selectDocument(String key) async {
    final file = await _pickFile();
    if (file == null) return;
    if (file.size > 2 * 1024 * 1024) {
      setState(() => _error = 'Ukuran setiap berkas maksimal 2 MB.');
      return;
    }
    setState(() {
      _documents[key] = file;
      _error = null;
    });
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_schoolId == null || _waveId == null || _gender == null) {
      setState(() => _error = 'Pilih sekolah, gelombang, dan jenis kelamin.');
      return;
    }
    const requiredDocuments = ['kartukeluarga', 'akte', 'rapor', 'ijazah'];
    if (requiredDocuments.any((key) => !_documents.containsKey(key))) {
      setState(() => _error = 'Unggah semua 4 dokumen wajib.');
      return;
    }
    setState(() {
      _registering = true;
      _error = null;
      _registration = null;
    });
    try {
      final response = await _api.register(
        fields: {
          'mst_sekolah_id': _schoolId,
          'ppdb_gelombang_id': _waveId,
          'nama_lengkap': _name.text.trim(),
          'email': _email.text.trim(),
          if (_password.text.isNotEmpty) 'password': _password.text,
          if (_nisn.text.isNotEmpty) 'nisn': _nisn.text.trim(),
          'jenis_kelamin': _gender,
          if (_phone.text.isNotEmpty) 'telp_hp': _phone.text.trim(),
          if (_originSchool.text.isNotEmpty)
            'asal_sekolah': _originSchool.text.trim(),
        },
        documents: _documents,
      );
      final data = response['data'];
      if (data is! Map) throw const FormatException();
      if (mounted)
        setState(() => _registration = Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } on FormatException {
      if (mounted) setState(() => _error = 'Respons pendaftaran tidak valid.');
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String)
      return data['message'] as String;
    return 'Pendaftaran tidak dapat diproses.';
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool email = false,
    bool obscure = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: email ? TextInputType.emailAddress : null,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return '$label wajib diisi.';
        if (email && text.isNotEmpty && !text.contains('@'))
          return 'Email tidak valid.';
        if (obscure && text.isNotEmpty && text.length < 6)
          return 'Password minimal 6 karakter.';
        return null;
      },
    ),
  );

  Future<void> _checkStatus() async {
    final number = _number.text.trim();
    if (number.isEmpty) {
      setState(() => _error = 'Nomor pendaftaran wajib diisi.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
      _status = null;
    });
    try {
      final status = await _api.applicationStatus(number);
      final data = status['data'];
      if (mounted && data is Map) {
        setState(() => _status = Map<String, dynamic>.from(data));
      }
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.response?.statusCode == 404
              ? 'Nomor pendaftaran tidak ditemukan.'
              : 'Status pendaftaran tidak dapat dimuat.',
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PPDB')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Penerimaan Peserta Didik Baru',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Lihat sekolah, gelombang aktif, atau cek status pendaftaran.',
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              DropdownButtonFormField<int>(
                key: const Key('ppdb-school'),
                decoration: const InputDecoration(labelText: 'Pilih sekolah'),
                value: _schoolId,
                items: _schools
                    .map(
                      (school) => DropdownMenuItem(
                        value: school['id'] as int?,
                        child: Text('${school['nama_sekolah'] ?? '-'}'),
                      ),
                    )
                    .toList(),
                onChanged: _selectSchool,
              ),
            ],
            if (_schoolId != null) ...[
              const SizedBox(height: 16),
              Text(
                'Gelombang aktif',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_waves.isEmpty)
                const Text('Tidak ada gelombang aktif.')
              else
                DropdownButtonFormField<int>(
                  key: const Key('ppdb-wave'),
                  decoration: const InputDecoration(
                    labelText: 'Pilih gelombang',
                  ),
                  value: _waveId,
                  items: _waves
                      .map(
                        (wave) => DropdownMenuItem(
                          value: wave['id'] as int?,
                          child: Text('${wave['nama_gelombang'] ?? '-'}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _waveId = value),
                ),
            ],
            const SizedBox(height: 28),
            Text(
              'Formulir pendaftaran',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field('Nama lengkap', _name, required: true),
                  _field('Email', _email, required: true, email: true),
                  _field(
                    'Password (opsional, minimal 6 karakter)',
                    _password,
                    obscure: true,
                  ),
                  _field('NISN', _nisn),
                  DropdownButtonFormField<String>(
                    key: const Key('ppdb-gender'),
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Jenis kelamin',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                      DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  _field('Nomor HP', _phone),
                  _field('Asal sekolah', _originSchool),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Dokumen wajib, maksimal 2 MB per berkas'),
                  ),
                  ...const [
                    ('kartukeluarga', 'Kartu Keluarga'),
                    ('akte', 'Akta kelahiran'),
                    ('rapor', 'Rapor'),
                    ('ijazah', 'Ijazah'),
                  ].map(
                    (item) => _DocumentButton(
                      label: item.$2,
                      file: _documents[item.$1],
                      onPressed: () => _selectDocument(item.$1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: const Key('ppdb-register'),
                    onPressed: _registering ? null : _register,
                    child: _registering
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Kirim pendaftaran'),
                  ),
                ],
              ),
            ),
            if (_registration != null)
              _RegistrationCard(registration: _registration!),
            const SizedBox(height: 28),
            Text(
              'Cek status pendaftaran',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('ppdb-number'),
              controller: _number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _checkStatus(),
              decoration: const InputDecoration(labelText: 'Nomor pendaftaran'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('ppdb-check-status'),
              onPressed: _checking ? null : _checkStatus,
              child: _checking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Cek status'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (_status != null) _StatusCard(status: _status!),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Map<String, dynamic> status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${status['nama_lengkap'] ?? '-'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text('Nomor: ${status['no_pendaftaran'] ?? '-'}'),
          Text('Status: ${status['status_pendaftaran'] ?? '-'}'),
          Text(
            'Gelombang: ${(status['gelombang'] as Map?)?['nama_gelombang'] ?? '-'}',
          ),
        ],
      ),
    ),
  );
}

class _DocumentButton extends StatelessWidget {
  final String label;
  final PlatformFile? file;
  final VoidCallback onPressed;

  const _DocumentButton({
    required this.label,
    required this.file,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.upload_file),
      label: Text(file == null ? 'Unggah $label' : '$label: ${file!.name}'),
    ),
  );
}

class _RegistrationCard extends StatelessWidget {
  final Map<String, dynamic> registration;

  const _RegistrationCard({required this.registration});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 16),
    color: AppColors.success.withAlpha(24),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendaftaran berhasil',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text('Nomor pendaftaran: ${registration['no_pendaftaran'] ?? '-'}'),
          Text('Status: ${registration['status_pendaftaran'] ?? '-'}'),
          const SizedBox(height: 6),
          const Text('Simpan nomor pendaftaran untuk cek status.'),
        ],
      ),
    ),
  );
}
