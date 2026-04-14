import 'package:dio/dio.dart';
import '../models/absensi_siswa_model.dart';
import '../models/absensi_guru_model.dart';

abstract class AbsensiRemoteDataSource {
  Future<List<AbsensiSiswaModel>> getAbsensiSiswaList(int siswaId);
  Future<List<AbsensiGuruModel>> getAbsensiGuruList(int guruId);
  Future<List<AbsensiSiswaModel>> getAbsensiSiswaGeneral({
    String? tanggalFrom,
    String? tanggalTo,
  });
}

class AbsensiRemoteDataSourceImpl implements AbsensiRemoteDataSource {
  final Dio _dio;

  const AbsensiRemoteDataSourceImpl(this._dio);

  @override
  Future<List<AbsensiSiswaModel>> getAbsensiSiswaList(int siswaId) async {
    final response = await _dio.get('/absensi-siswa/siswa/$siswaId');
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => AbsensiSiswaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AbsensiGuruModel>> getAbsensiGuruList(int guruId) async {
    final response = await _dio.get('/absensi-guru/guru/$guruId');
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => AbsensiGuruModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AbsensiSiswaModel>> getAbsensiSiswaGeneral({
    String? tanggalFrom,
    String? tanggalTo,
  }) async {
    final response = await _dio.get(
      '/absensi-siswa',
      queryParameters: {
        'tanggal_from': tanggalFrom,
        'tanggal_to': tanggalTo,
        'per_page': 100,
      }..removeWhere((_, v) => v == null),
    );
    // paginatedResponse wraps data directly in 'data' key (not nested)
    final raw = response.data['data'];
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else {
      list = (raw as Map<String, dynamic>?)?['data'] as List<dynamic>? ?? [];
    }
    return list
        .map((e) => AbsensiSiswaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
