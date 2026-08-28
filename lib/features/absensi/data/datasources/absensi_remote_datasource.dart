import 'package:dio/dio.dart';
import '../models/absensi_siswa_model.dart';
import '../models/absensi_guru_model.dart';
import '../../domain/entities/attendance_location.dart';

abstract class AbsensiRemoteDataSource {
  Future<AbsensiSiswaModel> checkIn(AttendanceLocation location);
  Future<AbsensiSiswaModel> checkOut(AttendanceLocation location);
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
  Future<AbsensiSiswaModel> checkIn(AttendanceLocation location) async {
    final response = await _dio.post(
      '/akademik/absensi-siswa/check-in',
      data: location.toJson(),
    );
    return _extractAttendance(response.data);
  }

  @override
  Future<AbsensiSiswaModel> checkOut(AttendanceLocation location) async {
    final response = await _dio.post(
      '/akademik/absensi-siswa/check-out',
      data: location.toJson(),
    );
    return _extractAttendance(response.data);
  }

  @override
  Future<List<AbsensiSiswaModel>> getAbsensiSiswaList(int siswaId) async {
    final response = await _dio.get(
      '/akademik/absensi-siswa',
      queryParameters: {'mst_siswa_id': siswaId, 'per_page': 100},
    );
    final list = _extractList(response.data);
    return list
        .map((e) => AbsensiSiswaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AbsensiGuruModel>> getAbsensiGuruList(int guruId) async {
    final response = await _dio.get(
      '/akademik/absensi-guru',
      queryParameters: {'mst_guru_id': guruId, 'per_page': 100},
    );
    final list = _extractList(response.data);
    return list
        .map((e) => AbsensiGuruModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AbsensiSiswaModel>> getAbsensiSiswaGeneral({
    String? tanggalFrom,
    String? tanggalTo,
  }) async {
    final response = await _dio.post(
      '/akademik/absensi-siswa/date-range',
      data: {'tanggal_awal': tanggalFrom, 'tanggal_akhir': tanggalTo}
        ..removeWhere((_, v) => v == null),
    );
    final list = _extractList(response.data);
    return list
        .map((e) => AbsensiSiswaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is! Map) return const [];
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  AbsensiSiswaModel _extractAttendance(dynamic body) {
    if (body is! Map || body['data'] is! Map) {
      throw const FormatException('Respons absensi tidak valid');
    }
    return AbsensiSiswaModel.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }
}
