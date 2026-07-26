import 'package:dio/dio.dart';
import '../models/jadwal_pelajaran_model.dart';

abstract class JadwalRemoteDataSource {
  /// GET /jadwal-pelajaran/kelas/{kelasId} — seluruh jadwal satu kelas
  Future<List<JadwalPelajaranModel>> getJadwalByKelas(int kelasId);

  /// GET /jadwal-pelajaran/kelas/{kelasId}/hari?hari=MON
  Future<List<JadwalPelajaranModel>> getJadwalByKelasHari(
    int kelasId,
    String hari,
  );

  /// GET /jadwal-pelajaran — index terpaginasi.
  /// Filter yang dipahami `JadwalPelajaranService::getAllJadwal()` pada mode
  /// pagination biasa hanyalah `kelas_id`, `guru_mapel_id`, dan `hari`.
  Future<List<JadwalPelajaranModel>> getJadwalList({
    int? kelasId,
    String? hari,
  });
}

class JadwalRemoteDataSourceImpl implements JadwalRemoteDataSource {
  final Dio _dio;

  const JadwalRemoteDataSourceImpl(this._dio);

  @override
  Future<List<JadwalPelajaranModel>> getJadwalByKelas(int kelasId) async {
    final response = await _dio.get('/jadwal-pelajaran/kelas/$kelasId');
    return _parseList(response.data);
  }

  @override
  Future<List<JadwalPelajaranModel>> getJadwalByKelasHari(
    int kelasId,
    String hari,
  ) async {
    final response = await _dio.get(
      '/jadwal-pelajaran/kelas/$kelasId/hari',
      // Controller membaca $request->input('hari') dan wajib diisi.
      queryParameters: {'hari': hari},
    );
    return _parseList(response.data);
  }

  @override
  Future<List<JadwalPelajaranModel>> getJadwalList({
    int? kelasId,
    String? hari,
  }) async {
    final response = await _dio.get(
      '/jadwal-pelajaran',
      queryParameters: <String, dynamic>{
        'kelas_id': kelasId,
        'hari': hari,
        // `per_page=all` didukung backend (AgGridControllerTrait) dan
        // mengembalikan seluruh baris dalam satu halaman — dibutuhkan karena
        // jadwal satu minggu penuh di-cache di bloc lalu difilter per hari.
        'per_page': 'all',
      }..removeWhere((_, v) => v == null),
    );
    return _parseList(response.data);
  }

  /// Envelope backend: `{ "success": true, "data": ... }`.
  /// Untuk endpoint terpaginasi `data` bisa berupa List langsung ATAU Map
  /// dengan key `data` di dalamnya — tangani keduanya. Bila server menjawab
  /// dalam mode AG Grid, datanya ada di key `rowData`.
  List<JadwalPelajaranModel> _parseList(dynamic responseData) {
    if (responseData is Map && responseData['rowData'] is List) {
      return _mapList(responseData['rowData'] as List<dynamic>);
    }
    final raw = responseData is Map ? responseData['data'] : null;
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else {
      list = (raw as Map<String, dynamic>?)?['data'] as List<dynamic>? ?? [];
    }
    return _mapList(list);
  }

  List<JadwalPelajaranModel> _mapList(List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map(JadwalPelajaranModel.fromJson)
        .toList();
  }
}
