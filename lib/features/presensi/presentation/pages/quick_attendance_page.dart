import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../jadwal/domain/entities/jadwal_pelajaran_entity.dart';

class QuickAttendancePage extends StatefulWidget {
  final JadwalPelajaranEntity jadwal;
  final DateTime tanggal;

  const QuickAttendancePage({
    super.key,
    required this.jadwal,
    required this.tanggal,
  });

  @override
  State<QuickAttendancePage> createState() => _QuickAttendancePageState();
}

class _QuickAttendancePageState extends State<QuickAttendancePage> {
  final Map<int, int> _changes = {};
  Map<String, dynamic>? _preview;
  bool _loading = true;
  String? _error;

  Dio get _dio => sl<ApiClient>().dio;
  int get _sessionId => ((_preview?['session'] as Map?)?['id'] as num).toInt();
  String get _date =>
      '${widget.tanggal.year.toString().padLeft(4, '0')}-${widget.tanggal.month.toString().padLeft(2, '0')}-${widget.tanggal.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _open();
  }

  Map<String, dynamic> _data(Response response) =>
      Map<String, dynamic>.from((response.data as Map)['data'] as Map);

  Future<void> _open() async {
    try {
      final opened = await _dio.post(
        '/akademik/presensi/sessions',
        data: {'trx_jadwal_pelajaran_id': widget.jadwal.id, 'tanggal': _date},
      );
      final session = _data(opened);
      final preview = await _dio.get(
        '/akademik/presensi/sessions/${session['id']}/preview',
      );
      if (mounted) {
        setState(() => _preview = _data(preview));
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _error =
              (e.response?.data as Map?)?['message']?.toString() ??
              'Gagal membuka sesi presensi',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    final response = await _dio.get(
      '/akademik/presensi/sessions/$_sessionId/preview',
    );
    if (mounted) setState(() => _preview = _data(response));
  }

  Future<void> _save() async {
    if (_changes.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _dio.post(
        '/akademik/presensi/bulk',
        data: {
          'session_id': _sessionId,
          'items': _changes.entries
              .map((e) => {'mst_siswa_id': e.key, 'status': e.value})
              .toList(),
        },
      );
      _changes.clear();
      await _refresh();
    } on DioException catch (e) {
      _show(
        (e.response?.data as Map?)?['message']?.toString() ??
            'Gagal menyimpan presensi',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finalize() async {
    if (_changes.isNotEmpty) {
      await _save();
    }
    await _refresh();
    if (!mounted) return;
    final missing = List<Map<String, dynamic>>.from(
      (_preview!['unmarked'] as List).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalisasi presensi?'),
        content: Text(
          missing.isEmpty
              ? 'Semua siswa sudah ditandai. Sesi tidak dapat diubah tanpa izin koreksi dan alasan.'
              : '${missing.length} siswa belum ditandai dan akan menjadi Alpha:\n\n${missing.map((e) => e['nama']).join(', ')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalisasi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await _dio.post(
        '/akademik/presensi/sessions/$_sessionId/finalize',
        data: {'confirm': true},
      );
      if (mounted) setState(() => _preview = _data(response));
    } on DioException catch (e) {
      _show(
        (e.response?.data as Map?)?['message']?.toString() ??
            'Gagal finalisasi presensi',
      );
    }
  }

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final finalized = (_preview?['session'] as Map?)?['finalized_at'] != null;
    final roster = _preview == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            (_preview!['roster'] as List).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
    return Scaffold(
      appBar: AppBar(title: Text('Presensi ${widget.jadwal.mapelNama ?? ''}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                if (finalized)
                  const MaterialBanner(
                    content: Text(
                      'Sesi sudah final. Koreksi dilakukan melalui alur berizin dengan alasan.',
                    ),
                    actions: [SizedBox.shrink()],
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: roster.length,
                    itemBuilder: (_, index) {
                      final student = roster[index];
                      final id = (student['id'] as num).toInt();
                      final status =
                          _changes[id] ?? (student['status'] as num?)?.toInt();
                      return ListTile(
                        title: Text(student['nama']?.toString() ?? '-'),
                        subtitle: Text(student['nis']?.toString() ?? ''),
                        trailing: DropdownButton<int>(
                          value: status,
                          hint: const Text('Belum'),
                          onChanged: finalized
                              ? null
                              : (value) =>
                                    setState(() => _changes[id] = value!),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Hadir')),
                            DropdownMenuItem(value: 2, child: Text('Izin')),
                            DropdownMenuItem(value: 3, child: Text('Sakit')),
                            DropdownMenuItem(value: 4, child: Text('Alpha')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (!finalized)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _changes.isEmpty ? null : _save,
                              child: Text('Simpan (${_changes.length})'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: _finalize,
                              child: const Text('Preview & Finalisasi'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
