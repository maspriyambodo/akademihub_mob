import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/keuangan_json.dart';
import '../models/laporan_periode_model.dart';
import '../models/pembayaran_online_model.dart';
import '../models/pembayaran_spp_model.dart';
import '../models/status_pembayaran_model.dart';
import '../models/tarif_spp_model.dart';
import '../models/tunggakan_model.dart';

abstract class KeuanganRemoteDataSource {
  Future<List<PembayaranSppModel>> getPembayaranList({
    String? search,
    int? tahun,
    int? bulan,
    String? status,
  });
  Future<PembayaranSppModel> getPembayaranDetail(int id);
  Future<List<PembayaranSppModel>> getPembayaranBySiswa(int siswaId);
  Future<StatusPembayaranModel> getStatusPembayaran(
    int siswaId, {
    String? tahunAjaran,
  });
  Future<List<TunggakanModel>> getTunggakan({
    required int siswaId,
    required int tarifSppId,
    required int tahun,
  });
  Future<DendaModel> hitungDenda({
    required int tarifSppId,
    required int bulan,
    required int tahun,
    String? tanggalBayar,
  });
  Future<LaporanPeriodeModel> getLaporanPeriode({
    int? tahun,
    int? bulanDari,
    int? bulanSampai,
    int? kelasId,
    int? tahunAjaranId,
  });

  Future<List<TarifSppModel>> getTarifList({String? search});
  Future<TarifSppModel> getTarifDetail(int id);
  Future<TarifSppModel> getTarifByKelas(int kelasId, {int? tahunAjaranId});

  Future<PembayaranSppModel> bayarSpp(Map<String, dynamic> body);
  Future<List<PembayaranSppModel>> bayarMultiple(Map<String, dynamic> body);
  Future<PembayaranOnlineModel> bayarOnline(Map<String, dynamic> body);
}

class KeuanganRemoteDataSourceImpl implements KeuanganRemoteDataSource {
  final Dio _dio;

  const KeuanganRemoteDataSourceImpl(this._dio);

  /// Ambil batas atas jumlah baris untuk mode AG-Grid.
  static const int _agGridEndRow = 300;

  // ── Helper envelope ───────────────────────────────────────────────────────

  /// `PembayaranSppController::index` & `TarifSppController::index` memakai
  /// `AgGridControllerTrait`, jadi bentuk response bisa TIGA macam:
  /// - dengan `startRow`/`endRow` → `{ "rowData": [...], "rowCount": n }`
  /// - tanpa keduanya            → `{ "data": [...] }`
  /// - paginator bersarang       → `{ "data": { "data": [...] } }`
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

  Map<String, dynamic> _extractMap(dynamic body, String pesanKosong) {
    final raw = body is Map ? body['data'] : null;
    final map = keuToMap(raw);
    if (map == null || map.isEmpty) {
      throw NotFoundException(pesanKosong);
    }
    return map;
  }

  List<PembayaranSppModel> _parsePembayaran(dynamic body) {
    final result = <PembayaranSppModel>[];
    for (final item in _extractList(body)) {
      final map = keuToMap(item);
      if (map != null) result.add(PembayaranSppModel.fromJson(map));
    }
    return result;
  }

  // ── Pembayaran SPP ────────────────────────────────────────────────────────

  @override
  Future<List<PembayaranSppModel>> getPembayaranList({
    String? search,
    int? tahun,
    int? bulan,
    String? status,
  }) async {
    final query = search?.trim() ?? '';

    // PENTING: filter `search` HANYA diterapkan di jalur AG-Grid
    // (`PembayaranSppService::applyAgGridAwareFilters`, dipakai oleh
    // `getTotalCount` + `getAllPembayaranSppWithSort`). Jalur pagination
    // tradisional (`getAllPembayaranSpp`) sama sekali tidak membaca `search`.
    // Karena itu kita selalu mengirim `startRow`/`endRow` supaya pencarian
    // benar-benar berjalan di server; parser tetap menangani ketiga bentuk
    // response.
    //
    // `sortModel` sengaja TIDAK dikirim: bentuknya array-of-object dan tidak
    // bisa diserialisasi rapi lewat query string Dio. Backend akan memakai
    // sort default (`id asc`), lalu Bloc mengurutkan ulang di sisi klien.
    final response = await _dio.get(
      '/keuangan/pembayaran-spp',
      queryParameters: <String, dynamic>{
        'startRow': 0,
        'endRow': _agGridEndRow,
        if (query.isNotEmpty) 'search': query,
        'tahun': ?tahun,
        'bulan': ?bulan,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return _parsePembayaran(response.data);
  }

  @override
  Future<PembayaranSppModel> getPembayaranDetail(int id) async {
    final response = await _dio.get('/keuangan/pembayaran-spp/$id');
    return PembayaranSppModel.fromJson(
      _extractMap(response.data, 'Detail pembayaran tidak tersedia'),
    );
  }

  @override
  Future<List<PembayaranSppModel>> getPembayaranBySiswa(int siswaId) async {
    final response = await _dio.get('/keuangan/pembayaran-spp/siswa/$siswaId');
    return _parsePembayaran(response.data);
  }

  @override
  Future<StatusPembayaranModel> getStatusPembayaran(
    int siswaId, {
    String? tahunAjaran,
  }) async {
    final response = await _dio.get(
      '/keuangan/pembayaran-spp/siswa/$siswaId/status',
      queryParameters: <String, dynamic>{
        if (tahunAjaran != null && tahunAjaran.isNotEmpty)
          'tahun_ajaran': tahunAjaran,
      },
    );
    return StatusPembayaranModel.fromJson(
      _extractMap(response.data, 'Status pembayaran tidak tersedia'),
    );
  }

  @override
  Future<List<TunggakanModel>> getTunggakan({
    required int siswaId,
    required int tarifSppId,
    required int tahun,
  }) async {
    // `tarif_spp_id` dan `tahun` WAJIB — backend memvalidasinya (422 bila kosong).
    final response = await _dio.get(
      '/keuangan/pembayaran-spp/siswa/$siswaId/tunggakan',
      queryParameters: <String, dynamic>{
        'tarif_spp_id': tarifSppId,
        'tahun': tahun,
      },
    );

    final raw = response.data is Map ? response.data['data'] : null;
    final result = <TunggakanModel>[];
    if (raw is List) {
      for (final item in raw) {
        final map = keuToMap(item);
        if (map != null) result.add(TunggakanModel.fromJson(map));
      }
    }
    return result;
  }

  @override
  Future<DendaModel> hitungDenda({
    required int tarifSppId,
    required int bulan,
    required int tahun,
    String? tanggalBayar,
  }) async {
    final response = await _dio.get(
      '/keuangan/pembayaran-spp/hitung-denda',
      queryParameters: <String, dynamic>{
        'tarif_spp_id': tarifSppId,
        'bulan': bulan,
        'tahun': tahun,
        if (tanggalBayar != null && tanggalBayar.isNotEmpty)
          'tanggal_bayar': tanggalBayar,
      },
    );
    return DendaModel.fromJson(
      _extractMap(response.data, 'Perhitungan denda tidak tersedia'),
    );
  }

  @override
  Future<LaporanPeriodeModel> getLaporanPeriode({
    int? tahun,
    int? bulanDari,
    int? bulanSampai,
    int? kelasId,
    int? tahunAjaranId,
  }) async {
    final response = await _dio.get(
      '/keuangan/pembayaran-spp/laporan-periode',
      queryParameters: <String, dynamic>{
        'tahun': ?tahun,
        'bulan_dari': ?bulanDari,
        'bulan_sampai': ?bulanSampai,
        'mst_kelas_id': ?kelasId,
        'tahun_ajaran_id': ?tahunAjaranId,
      },
    );
    return LaporanPeriodeModel.fromJson(
      _extractMap(response.data, 'Laporan periode tidak tersedia'),
    );
  }

  // ── Tarif SPP ─────────────────────────────────────────────────────────────

  @override
  Future<List<TarifSppModel>> getTarifList({String? search}) async {
    final query = search?.trim() ?? '';
    final response = await _dio.get(
      '/keuangan/tarif-spp',
      queryParameters: <String, dynamic>{
        'startRow': 0,
        'endRow': _agGridEndRow,
        if (query.isNotEmpty) 'search': query,
      },
    );

    final result = <TarifSppModel>[];
    for (final item in _extractList(response.data)) {
      final map = keuToMap(item);
      if (map != null) result.add(TarifSppModel.fromJson(map));
    }
    return result;
  }

  @override
  Future<TarifSppModel> getTarifDetail(int id) async {
    final response = await _dio.get('/keuangan/tarif-spp/$id');
    return TarifSppModel.fromJson(
      _extractMap(response.data, 'Tarif SPP tidak ditemukan'),
    );
  }

  @override
  Future<TarifSppModel> getTarifByKelas(
    int kelasId, {
    int? tahunAjaranId,
  }) async {
    // Endpoint ini mengembalikan SATU objek (bukan list) dan 404 bila kelas
    // tersebut belum memiliki tarif pada tahun ajaran terkait.
    final response = await _dio.get(
      '/keuangan/tarif-spp/kelas/$kelasId',
      queryParameters: <String, dynamic>{
        'tahun_ajaran_id': ?tahunAjaranId,
      },
    );
    return TarifSppModel.fromJson(
      _extractMap(response.data, 'Tarif SPP untuk kelas ini belum diatur'),
    );
  }

  // ── Aksi tulis ────────────────────────────────────────────────────────────

  @override
  Future<PembayaranSppModel> bayarSpp(Map<String, dynamic> body) async {
    final response = await _dio.post(
      '/keuangan/pembayaran-spp/bayar',
      data: body,
    );
    return PembayaranSppModel.fromJson(
      _extractMap(response.data, 'Pembayaran gagal dicatat'),
    );
  }

  @override
  Future<List<PembayaranSppModel>> bayarMultiple(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      '/keuangan/pembayaran-spp/bayar-multiple',
      data: body,
    );
    return _parsePembayaran(response.data);
  }

  @override
  Future<PembayaranOnlineModel> bayarOnline(Map<String, dynamic> body) async {
    final response = await _dio.post(
      '/keuangan/pembayaran-spp/bayar-online',
      data: body,
    );
    final model = PembayaranOnlineModel.fromJson(
      _extractMap(response.data, 'Transaksi pembayaran online gagal dibuat'),
    );

    if (model.checkoutUrl == null || model.checkoutUrl!.trim().isEmpty) {
      throw const ServerException(
        'Server tidak mengirim tautan pembayaran Midtrans',
      );
    }
    return model;
  }
}
