import 'package:dio/dio.dart';

import '../models/log_akses_materi_model.dart';
import '../models/materi_model.dart';

abstract class MateriRemoteDataSource {
  Future<List<MateriModel>> getMateriList({int? status});
  Future<MateriModel> getMateriDetail(int id);
  Future<List<MateriModel>> getMateriByGuruMapel(int guruMapelId);
  Future<List<MateriPopulerModel>> getMateriPopuler({int limit});
  Future<MateriModel> createMateri({
    required int guruMapelId,
    required String judul,
    String? deskripsi,
    String? fileMateri,
    String? linkVideo,
    int? status,
  });
  Future<MateriModel> updateMateri({
    required int id,
    int? guruMapelId,
    String? judul,
    String? deskripsi,
    String? fileMateri,
    String? linkVideo,
    int? status,
  });
  Future<bool> deleteMateri(int id);

  Future<List<LogAksesMateriModel>> getLogAksesByMateri(int materiId);
  Future<List<LogAksesMateriModel>> getLogAksesBySiswa(int siswaId);

  Future<LogAksesMateriModel> catatAkses({
    required int materiId,
    required int siswaId,
    required int kelasId,
  });

  Future<LogAksesMateriModel> updateDurasi({
    required int logId,
    required int durasiDetik,
  });
}

class MateriRemoteDataSourceImpl implements MateriRemoteDataSource {
  final Dio _dio;

  const MateriRemoteDataSourceImpl(this._dio);

  /// `MateriController`/`LogAksesMateriController` memakai `AgGridControllerTrait`:
  /// - tanpa `startRow`/`endRow` → `{ "data": [...] }` atau `{ "data": { "data": [...] } }`
  /// - dengan `startRow`/`endRow` → `{ "rowData": [...] }`
  ///
  /// Ketiga bentuk ditangani di sini.
  List<dynamic> _extractList(dynamic body) {
    if (body is! Map) return const [];

    final rowData = body['rowData'];
    if (rowData is List) return rowData;

    final raw = body['data'];
    if (raw is List) return raw;
    if (raw is Map) {
      final nested = raw['data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  Map<String, dynamic> _extractObject(dynamic body) {
    if (body is Map) {
      final raw = body['data'];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return Map<String, dynamic>.from(body);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMaps(dynamic body) {
    final hasil = <Map<String, dynamic>>[];
    for (final item in _extractList(body)) {
      if (item is Map<String, dynamic>) {
        hasil.add(item);
      } else if (item is Map) {
        hasil.add(Map<String, dynamic>.from(item));
      }
    }
    return hasil;
  }

  // ── Materi ─────────────────────────────────────────────────────────────────

  /// Memakai jalur pagination tradisional (`per_page`) karena hanya jalur ini
  /// yang mengurutkan `created_at desc` di `MateriService::getAllMateri`.
  /// Pencarian judul dilakukan client-side (lihat `MateriBloc`).
  @override
  Future<List<MateriModel>> getMateriList({int? status}) async {
    final response = await _dio.get(
      '/akademik/materi',
      queryParameters: <String, dynamic>{'per_page': 200, 'status': ?status},
    );
    return _asMaps(response.data).map(MateriModel.fromJson).toList();
  }

  @override
  Future<MateriModel> getMateriDetail(int id) async {
    final response = await _dio.get('/akademik/materi/$id');
    return MateriModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<List<MateriModel>> getMateriByGuruMapel(int guruMapelId) async {
    final response = await _dio.get('/akademik/materi/guru-mapel/$guruMapelId');
    return _asMaps(response.data).map(MateriModel.fromJson).toList();
  }

  @override
  Future<List<MateriPopulerModel>> getMateriPopuler({int limit = 5}) async {
    final response = await _dio.get(
      '/akademik/log-akses-materi/popular',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return _asMaps(response.data).map(MateriPopulerModel.fromJson).toList();
  }

  @override
  Future<MateriModel> createMateri({
    required int guruMapelId,
    required String judul,
    String? deskripsi,
    String? fileMateri,
    String? linkVideo,
    int? status,
  }) async {
    final response = await _dio.post(
      '/akademik/materi',
      data: <String, dynamic>{
        'mst_guru_mapel_id': guruMapelId,
        'judul': judul,
        'deskripsi': ?deskripsi,
        'file_materi': ?fileMateri,
        'link_video': ?linkVideo,
        'status': ?status,
      },
    );
    return MateriModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<MateriModel> updateMateri({
    required int id,
    int? guruMapelId,
    String? judul,
    String? deskripsi,
    String? fileMateri,
    String? linkVideo,
    int? status,
  }) async {
    final response = await _dio.put(
      '/akademik/materi/$id',
      data: <String, dynamic>{
        'mst_guru_mapel_id': ?guruMapelId,
        'judul': ?judul,
        'deskripsi': ?deskripsi,
        'file_materi': ?fileMateri,
        'link_video': ?linkVideo,
        'status': ?status,
      },
    );
    return MateriModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<bool> deleteMateri(int id) async {
    await _dio.delete('/akademik/materi/$id');
    return true;
  }

  // ── Log akses materi ───────────────────────────────────────────────────────

  @override
  Future<List<LogAksesMateriModel>> getLogAksesByMateri(int materiId) async {
    final response = await _dio.get(
      '/akademik/log-akses-materi/materi/$materiId',
    );
    return _asMaps(response.data).map(LogAksesMateriModel.fromJson).toList();
  }

  @override
  Future<List<LogAksesMateriModel>> getLogAksesBySiswa(int siswaId) async {
    final response = await _dio.get(
      '/akademik/log-akses-materi/siswa/$siswaId',
    );
    return _asMaps(response.data).map(LogAksesMateriModel.fromJson).toList();
  }

  /// `kelas_id` wajib dikirim: `LogAksesMateriService::createLogAkses`
  /// membacanya tanpa fallback dan kolomnya NOT NULL di database.
  @override
  Future<LogAksesMateriModel> catatAkses({
    required int materiId,
    required int siswaId,
    required int kelasId,
  }) async {
    final response = await _dio.post(
      '/akademik/log-akses-materi',
      data: <String, dynamic>{
        'materi_id': materiId,
        'siswa_id': siswaId,
        'kelas_id': kelasId,
        'waktu_akses': _formatWaktu(DateTime.now()),
        'durasi_detik': 0,
        'status': 1,
        'progress_persen': 0,
      },
    );
    return LogAksesMateriModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<LogAksesMateriModel> updateDurasi({
    required int logId,
    required int durasiDetik,
  }) async {
    final response = await _dio.put(
      '/akademik/log-akses-materi/$logId/durasi',
      data: <String, dynamic>{'durasi_detik': durasiDetik},
    );
    return LogAksesMateriModel.fromJson(_extractObject(response.data));
  }

  /// Format "YYYY-MM-DD HH:mm:ss" — aman untuk validasi `date` di backend.
  String _formatWaktu(DateTime dt) {
    String dua(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${dua(dt.month)}-${dua(dt.day)} '
        '${dua(dt.hour)}:${dua(dt.minute)}:${dua(dt.second)}';
  }
}
