import 'package:dio/dio.dart';
import '../models/tugas_model.dart';
import '../models/tugas_siswa_model.dart';

abstract class TugasRemoteDataSource {
  Future<List<TugasModel>> getTugasList({int? status, String? search});
  Future<TugasModel> getTugasDetail(int id);
  Future<List<TugasModel>> getTugasByKelas(int kelasId);
  Future<List<TugasModel>> getTugasByGuruMapel(int guruMapelId);
  Future<TugasModel> createTugas({
    required int guruMapelId,
    required int kelasId,
    required String judul,
    required String tenggatWaktu,
    String? deskripsi,
    String? fileLampiran,
    int? status,
  });
  Future<TugasModel> updateTugas({
    required int id,
    int? guruMapelId,
    int? kelasId,
    String? judul,
    String? deskripsi,
    String? fileLampiran,
    String? tenggatWaktu,
    int? status,
  });
  Future<bool> deleteTugas(int id);

  Future<List<TugasSiswaModel>> getPengumpulanList();
  Future<List<TugasSiswaModel>> getPengumpulanByTugas(int tugasId);
  Future<List<TugasSiswaModel>> getPengumpulanBySiswa(int siswaId);

  Future<TugasSiswaModel> kumpulkan({
    required int siswaId,
    required int tugasId,
    String? jawaban,
    String? fileJawaban,
  });

  Future<TugasSiswaModel> nilai({
    required int pengumpulanId,
    required double nilai,
    String? catatanGuru,
  });
}

class TugasRemoteDataSourceImpl implements TugasRemoteDataSource {
  final Dio _dio;

  const TugasRemoteDataSourceImpl(this._dio);

  /// Envelope backend: `{ "success": true, "data": ... }`.
  /// Untuk endpoint terpaginasi `data` bisa berupa List langsung ATAU Map
  /// dengan key `data` di dalamnya.
  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is! Map) return const [];
    final raw = responseData['data'];
    if (raw is List) return raw;
    if (raw is Map) return raw['data'] as List<dynamic>? ?? const [];
    return const [];
  }

  Map<String, dynamic> _extractObject(dynamic responseData) {
    if (responseData is Map) {
      final raw = responseData['data'];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return Map<String, dynamic>.from(responseData);
    }
    return <String, dynamic>{};
  }

  // ── Tugas ──────────────────────────────────────────────────────────────────

  @override
  Future<List<TugasModel>> getTugasList({int? status, String? search}) async {
    final response = await _dio.get(
      '/akademik/tugas',
      queryParameters: {'per_page': 100, 'status': status, 'search': search}
        ..removeWhere((_, v) => v == null),
    );
    return _extractList(
      response.data,
    ).map((e) => TugasModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TugasModel> getTugasDetail(int id) async {
    final response = await _dio.get('/akademik/tugas/$id');
    return TugasModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<List<TugasModel>> getTugasByKelas(int kelasId) async {
    final response = await _dio.get('/akademik/tugas/kelas/$kelasId');
    return _extractList(
      response.data,
    ).map((e) => TugasModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TugasModel>> getTugasByGuruMapel(int guruMapelId) async {
    final response = await _dio.get('/akademik/tugas/guru-mapel/$guruMapelId');
    return _extractList(
      response.data,
    ).map((e) => TugasModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TugasModel> createTugas({
    required int guruMapelId,
    required int kelasId,
    required String judul,
    required String tenggatWaktu,
    String? deskripsi,
    String? fileLampiran,
    int? status,
  }) async {
    final response = await _dio.post(
      '/akademik/tugas',
      data: <String, dynamic>{
        'mst_guru_mapel_id': guruMapelId,
        'mst_kelas_id': kelasId,
        'judul': judul,
        'tenggat_waktu': tenggatWaktu,
        'deskripsi': ?deskripsi,
        'file_lampiran': ?fileLampiran,
        'status': ?status,
      },
    );
    return TugasModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<TugasModel> updateTugas({
    required int id,
    int? guruMapelId,
    int? kelasId,
    String? judul,
    String? deskripsi,
    String? fileLampiran,
    String? tenggatWaktu,
    int? status,
  }) async {
    final response = await _dio.put(
      '/akademik/tugas/$id',
      data: <String, dynamic>{
        'mst_guru_mapel_id': ?guruMapelId,
        'mst_kelas_id': ?kelasId,
        'judul': ?judul,
        'deskripsi': ?deskripsi,
        'file_lampiran': ?fileLampiran,
        'tenggat_waktu': ?tenggatWaktu,
        'status': ?status,
      },
    );
    return TugasModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<bool> deleteTugas(int id) async {
    await _dio.delete('/akademik/tugas/$id');
    return true;
  }

  // ── Pengumpulan (tugas-siswa) ──────────────────────────────────────────────

  @override
  Future<List<TugasSiswaModel>> getPengumpulanList() async {
    final response = await _dio.get(
      '/akademik/tugas-siswa',
      queryParameters: const {'per_page': 100},
    );
    return _extractList(
      response.data,
    ).map((e) => TugasSiswaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TugasSiswaModel>> getPengumpulanByTugas(int tugasId) async {
    final response = await _dio.get('/akademik/tugas-siswa/tugas/$tugasId');
    return _extractList(
      response.data,
    ).map((e) => TugasSiswaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TugasSiswaModel>> getPengumpulanBySiswa(int siswaId) async {
    final response = await _dio.get('/akademik/tugas-siswa/siswa/$siswaId');
    return _extractList(
      response.data,
    ).map((e) => TugasSiswaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TugasSiswaModel> kumpulkan({
    required int siswaId,
    required int tugasId,
    String? jawaban,
    String? fileJawaban,
  }) async {
    // `waktu_kumpul` wajib dikirim: backend memakainya untuk menghitung
    // status (1 = Tepat Waktu, 2 = Terlambat) terhadap tenggat_waktu tugas.
    final body = <String, dynamic>{
      'jawaban': jawaban,
      'file_jawaban': fileJawaban,
      'waktu_kumpul': _formatWaktu(DateTime.now()),
    }..removeWhere((_, v) => v == null || (v is String && v.isEmpty));

    final response = await _dio.post(
      '/akademik/tugas-siswa/siswa/$siswaId/tugas/$tugasId/kumpulkan',
      data: body,
    );
    return TugasSiswaModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<TugasSiswaModel> nilai({
    required int pengumpulanId,
    required double nilai,
    String? catatanGuru,
  }) async {
    final body = <String, dynamic>{
      'nilai': nilai,
      if (catatanGuru != null && catatanGuru.isNotEmpty)
        'catatan_guru': catatanGuru,
    };

    final response = await _dio.post(
      '/akademik/tugas-siswa/$pengumpulanId/nilai',
      data: body,
    );
    return TugasSiswaModel.fromJson(_extractObject(response.data));
  }

  /// Format "YYYY-MM-DD HH:mm:ss" — aman untuk `Carbon::parse` di backend.
  String _formatWaktu(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}
