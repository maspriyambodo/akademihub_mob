import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/responsive.dart';

enum AkademikPublikasiType { materi, tugas }

class AkademikPublikasiFormPage extends StatefulWidget {
  final AkademikPublikasiType type;

  const AkademikPublikasiFormPage({super.key, required this.type});

  @override
  State<AkademikPublikasiFormPage> createState() =>
      _AkademikPublikasiFormPageState();
}

class _AkademikPublikasiFormPageState extends State<AkademikPublikasiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _judul = TextEditingController();
  final _deskripsi = TextEditingController();
  final _video = TextEditingController();
  final _api = sl<ApiClient>().dio;
  List<_Pilihan> _guruMapel = const [];
  List<_Pilihan> _kelas = const [];
  int? _guruMapelId;
  int? _kelasId;
  DateTime? _tenggat;
  String? _filePath;
  String? _error;
  bool _loading = true;
  bool _sending = false;

  bool get _isTugas => widget.type == AkademikPublikasiType.tugas;
  String get _label => _isTugas ? 'Tugas' : 'Materi';

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    _video.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final responses = await Future.wait([
        _api.get('/guru-mapel/saya'),
        if (_isTugas)
          _api.get('/kelas', queryParameters: const {'per_page': 'all'}),
      ]);
      if (!mounted) return;
      setState(() {
        _guruMapel = _parseGuruMapel(responses.first.data);
        _kelas = _isTugas ? _parseKelas(responses[1].data) : const [];
        _loading = false;
      });
    } on DioException catch (error) {
      if (mounted) {
        setState(() {
          _error = _message(error, 'Gagal memuat pilihan pengajaran');
          _loading = false;
        });
      }
    }
  }

  List<_Pilihan> _parseGuruMapel(dynamic body) {
    return _rows(body).map((row) {
      final mapel = row['mapel'] as Map?;
      final mapelNama = mapel?['nama']?.toString() ?? 'Mata pelajaran';
      return _Pilihan((row['id'] as num).toInt(), mapelNama);
    }).toList();
  }

  List<_Pilihan> _parseKelas(dynamic body) => _rows(body)
      .map(
        (row) => _Pilihan(
          (row['id'] as num).toInt(),
          row['nama_kelas']?.toString() ?? 'Kelas',
        ),
      )
      .toList();

  List<Map<String, dynamic>> _rows(dynamic body) {
    if (body is! Map) return const [];
    final raw = body['data'];
    final rows = raw is List
        ? raw
        : raw is Map
        ? raw['data']
        : null;
    return rows is List
        ? rows.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : const [];
  }

  Future<void> _pilihFile() async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: false,
    );
    final file = pick?.files.single;
    if (file?.path == null) return;
    if (file!.size > 2 * 1024 * 1024) {
      setState(() => _error = 'Ukuran berkas maksimal 2 MB');
      return;
    }
    setState(() => _sending = true);
    try {
      final response = await _api.post(
        '/files/upload',
        data: FormData.fromMap({
          'folder': _isTugas ? 'tugas' : 'materi',
          'file': await MultipartFile.fromFile(file.path!, filename: file.name),
        }),
      );
      final data = response.data is Map ? response.data['data'] : null;
      final path = data is Map ? data['file_path']?.toString() : null;
      if (path == null || path.isEmpty) throw const FormatException();
      if (mounted) {
        setState(() => _filePath = path);
      }
    } on DioException catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Unggah berkas gagal'));
      }
    } on FormatException {
      if (mounted) {
        setState(() => _error = 'Respons unggah tidak valid');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _simpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_guruMapelId == null || (_isTugas && _kelasId == null)) {
      setState(
        () => _error = 'Pilih mata pelajaran${_isTugas ? ' dan kelas' : ''}',
      );
      return;
    }
    if (_isTugas && _tenggat == null) {
      setState(() => _error = 'Pilih tenggat waktu');
      return;
    }
    setState(() => _sending = true);
    final body = <String, dynamic>{
      'mst_guru_mapel_id': _guruMapelId,
      'judul': _judul.text.trim(),
      'deskripsi': _deskripsi.text.trim(),
      'status': 1,
      if (_isTugas) ...{
        'mst_kelas_id': _kelasId,
        'file_lampiran': _filePath,
        'tenggat_waktu': _formatDate(_tenggat!),
      } else ...{
        'file_materi': _filePath,
        'link_video': _video.text.trim(),
      },
    }..removeWhere((_, value) => value == null || value == '');
    try {
      await _api.post('/akademik/${_isTugas ? 'tugas' : 'materi'}', data: body);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on DioException catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Gagal menyimpan $_label'));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _formatDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} 23:59:59';

  String _message(DioException error, String fallback) {
    final body = error.response?.data;
    return body is Map ? body['message']?.toString() ?? fallback : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah $_label'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: Responsive.pagePadding(context),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.lebarKontenMaks(context),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: _guruMapelId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Mata pelajaran',
                            ),
                            items: _guruMapel
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.label, maxLines: 2),
                                  ),
                                )
                                .toList(),
                            onChanged: _sending
                                ? null
                                : (value) =>
                                      setState(() => _guruMapelId = value),
                            validator: (value) =>
                                value == null ? 'Wajib dipilih' : null,
                          ),
                          if (_guruMapel.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Belum ada mata pelajaran yang ditugaskan untuk akun ini.',
                              ),
                            ),
                          if (_isTugas) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: _kelasId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Kelas',
                              ),
                              items: _kelas
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item.id,
                                      child: Text(item.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _sending
                                  ? null
                                  : (value) => setState(() => _kelasId = value),
                              validator: (value) =>
                                  value == null ? 'Wajib dipilih' : null,
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _judul,
                            maxLength: 255,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Judul $_label',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Judul wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _deskripsi,
                            minLines: 4,
                            maxLines: 7,
                            decoration: const InputDecoration(
                              labelText: 'Instruksi atau deskripsi',
                              alignLabelWithHint: true,
                            ),
                          ),
                          if (!_isTugas) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _video,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Tautan video (opsional)',
                                prefixIcon: Icon(Icons.video_library_outlined),
                              ),
                            ),
                          ],
                          if (_isTugas) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _sending
                                  ? null
                                  : () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(
                                          DateTime.now().year + 5,
                                        ),
                                        initialDate: _tenggat ?? DateTime.now(),
                                      );
                                      if (date != null && mounted) {
                                        setState(() => _tenggat = date);
                                      }
                                    },
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(
                                _tenggat == null
                                    ? 'Pilih tenggat waktu'
                                    : 'Tenggat: ${_formatDate(_tenggat!).substring(0, 10)}',
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _sending ? null : _pilihFile,
                            icon: const Icon(Icons.attach_file_outlined),
                            label: Text(
                              _filePath == null
                                  ? 'Lampirkan berkas (opsional)'
                                  : 'Berkas siap diunggah',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _sending ? null : _simpan,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            child: Text(
                              _sending
                                  ? 'Menyimpan...'
                                  : 'Publikasikan $_label',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Pilihan {
  final int id;
  final String label;
  const _Pilihan(this.id, this.label);
}
