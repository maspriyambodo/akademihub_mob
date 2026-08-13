import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/tmb_hasil_model.dart';
import '../models/tmb_jawaban_model.dart';
import '../models/tmb_pertanyaan_model.dart';
import '../models/tmb_peserta_model.dart';
import '../models/tmb_tes_model.dart';

abstract class TmbRemoteDataSource {
  Future<List<TmbTesModel>> getTesList();
  Future<List<TmbTesModel>> getTesByKelas(int kelasId);
  Future<List<TmbPertanyaanModel>> getPertanyaanByTes(int tesId);
  Future<List<TmbPertanyaanModel>> getPertanyaanViaTesDetail(int tesId);
  Future<List<TmbPesertaModel>> getPesertaBySiswa(int siswaId);
  Future<List<TmbPesertaModel>> getPesertaByTes(int tesId);
  Future<TmbPesertaModel> daftarPeserta({
    required int tesId,
    required int siswaId,
  });
  Future<TmbPesertaModel> mulaiTes(int pesertaId);
  Future<TmbPesertaModel> selesaikanTes(int pesertaId);
  Future<TmbJawabanModel> kirimJawaban({
    required int pesertaId,
    required int pertanyaanId,
    int? opsiId,
    String? jawabanTeks,
  });
  Future<List<TmbJawabanModel>> getJawabanByPeserta(int pesertaId);
  Future<List<TmbHasilModel>> getHasilByPeserta(int pesertaId);
}

class TmbRemoteDataSourceImpl implements TmbRemoteDataSource {
  final Dio _dio;

  const TmbRemoteDataSourceImpl(this._dio);

  /// Endpoint index memakai `AgGridControllerTrait`; envelope bisa berupa
  /// `{"rowData": [...]}`, `{"data": [...]}`, atau `{"data": {"data": [...]}}`.
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

  Map<String, dynamic> _extractMap(dynamic body) {
    final raw = body is Map ? body['data'] : null;
    if (raw is Map<String, dynamic> && raw.isNotEmpty) return raw;
    throw const ServerException('Format response tidak dikenali');
  }

  @override
  Future<List<TmbTesModel>> getTesList() async {
    final response = await _dio.get(
      '/akademik/tes-minat-bakat',
      queryParameters: const {'per_page': 'all'},
    );
    return _extractList(
      response.data,
    ).whereType<Map<String, dynamic>>().map(TmbTesModel.fromJson).toList();
  }

  @override
  Future<List<TmbTesModel>> getTesByKelas(int kelasId) async {
    final response = await _dio.get('/akademik/tes-minat-bakat/kelas/$kelasId');
    return _extractList(
      response.data,
    ).whereType<Map<String, dynamic>>().map(TmbTesModel.fromJson).toList();
  }

  @override
  Future<List<TmbPertanyaanModel>> getPertanyaanByTes(int tesId) async {
    final response = await _dio.get(
      '/akademik/tes-minat-bakat-pertanyaan/tes/$tesId',
    );
    return _sortPertanyaan(
      _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(TmbPertanyaanModel.fromJson)
          .toList(),
    );
  }

  /// Jalur untuk user tanpa izin `tes-minat-bakat-pertanyaan.view` (siswa):
  /// `GET /tes-minat-bakat/{id}` memuat relasi `pertanyaan.opsi`.
  @override
  Future<List<TmbPertanyaanModel>> getPertanyaanViaTesDetail(int tesId) async {
    final response = await _dio.get('/akademik/tes-minat-bakat/$tesId');
    final tes = _extractMap(response.data);
    final raw = tes['pertanyaan'];
    if (raw is! List) return const [];
    return _sortPertanyaan(
      raw
          .whereType<Map<String, dynamic>>()
          .map(TmbPertanyaanModel.fromJson)
          .toList(),
    );
  }

  List<TmbPertanyaanModel> _sortPertanyaan(List<TmbPertanyaanModel> list) {
    list.sort((a, b) {
      final byUrut = a.nomorUrut.compareTo(b.nomorUrut);
      return byUrut != 0 ? byUrut : a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Future<List<TmbPesertaModel>> getPesertaBySiswa(int siswaId) async {
    final response = await _dio.get(
      '/akademik/tes-minat-bakat-peserta/siswa/$siswaId',
    );
    return _extractList(
      response.data,
    ).whereType<Map<String, dynamic>>().map(TmbPesertaModel.fromJson).toList();
  }

  @override
  Future<List<TmbPesertaModel>> getPesertaByTes(int tesId) async {
    final response = await _dio.get(
      '/akademik/tes-minat-bakat-peserta/tes/$tesId',
    );
    return _extractList(
      response.data,
    ).whereType<Map<String, dynamic>>().map(TmbPesertaModel.fromJson).toList();
  }

  @override
  Future<TmbPesertaModel> daftarPeserta({
    required int tesId,
    required int siswaId,
  }) async {
    final response = await _dio.post(
      '/akademik/tes-minat-bakat-peserta',
      data: {'tes_id': tesId, 'siswa_id': siswaId},
    );
    return TmbPesertaModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<TmbPesertaModel> mulaiTes(int pesertaId) async {
    final response = await _dio.post(
      '/akademik/tes-minat-bakat-peserta/$pesertaId/mulai',
    );
    return TmbPesertaModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<TmbPesertaModel> selesaikanTes(int pesertaId) async {
    final response = await _dio.post(
      '/akademik/tes-minat-bakat-peserta/$pesertaId/selesaikan',
    );
    return TmbPesertaModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<TmbJawabanModel> kirimJawaban({
    required int pesertaId,
    required int pertanyaanId,
    int? opsiId,
    String? jawabanTeks,
  }) async {
    final response = await _dio.post(
      '/akademik/tes-minat-bakat-jawaban',
      data: <String, dynamic>{
        'peserta_id': pesertaId,
        'pertanyaan_id': pertanyaanId,
        'opsi_id': ?opsiId,
        'jawaban_teks': ?jawabanTeks,
      },
    );
    return TmbJawabanModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<List<TmbJawabanModel>> getJawabanByPeserta(int pesertaId) async {
    final response = await _dio.get(
      '/akademik/tes-minat-bakat-jawaban',
      queryParameters: {'peserta_id': pesertaId, 'per_page': 'all'},
    );
    return _extractList(
      response.data,
    ).whereType<Map<String, dynamic>>().map(TmbJawabanModel.fromJson).toList();
  }

  @override
  Future<List<TmbHasilModel>> getHasilByPeserta(int pesertaId) async {
    final response = await _dio.get(
      '/akademik/tes-minat-bakat-hasil/peserta/$pesertaId',
    );
    return _extractList(
      response.data,
    ).whereType<Map<String, dynamic>>().map(TmbHasilModel.fromJson).toList();
  }
}
