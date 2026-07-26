import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/buku_model.dart';
import '../models/buku_riwayat_model.dart';
import '../models/peminjaman_buku_model.dart';

abstract class PerpustakaanRemoteDataSource {
  Future<List<BukuModel>> getBukuList({int perPage, String? search});
  Future<List<BukuModel>> getBukuAvailable();
  Future<BukuModel> getBukuDetail(int bukuId);
  Future<BukuRiwayatModel> getRiwayatBuku(int bukuId);

  Future<List<PeminjamanBukuModel>> getPeminjamanList({int perPage});
  Future<List<PeminjamanBukuModel>> getPeminjamanBySiswa(int siswaId);
  Future<List<PeminjamanBukuModel>> getPeminjamanOverdue();

  Future<PeminjamanBukuModel> createPeminjaman({
    required int siswaId,
    required int bukuId,
    String? tanggalPinjam,
    required String tanggalJatuhTempo,
  });

  Future<PeminjamanBukuModel> prosesPengembalian(int peminjamanId);
}

class PerpustakaanRemoteDataSourceImpl implements PerpustakaanRemoteDataSource {
  final Dio _dio;

  const PerpustakaanRemoteDataSourceImpl(this._dio);

  /// `BukuController::index` dan `PeminjamanBukuController::index` memakai
  /// `AgGridControllerTrait`, jadi bentuk respons bisa tiga macam:
  /// - `{ "rowData": [...] }`         → mode AG-Grid (`startRow`/`endRow` dikirim)
  /// - `{ "data": [...] }`            → `paginatedResponse` (cursor paginate)
  /// - `{ "data": { "data": [...] } }`→ varian nested
  /// Endpoint non-index (`/available`, `/overdue`, `/siswa/{id}`) selalu
  /// memakai bentuk kedua.
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
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return Map<String, dynamic>.from(body);
    }
    return <String, dynamic>{};
  }

  List<BukuModel> _parseBuku(dynamic body) => _extractList(body)
      .whereType<Map>()
      .map((e) => BukuModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  List<PeminjamanBukuModel> _parsePeminjaman(dynamic body) =>
      _extractList(body)
          .whereType<Map>()
          .map(
            (e) => PeminjamanBukuModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();

  // ── Buku ───────────────────────────────────────────────────────────────────

  @override
  Future<List<BukuModel>> getBukuList({int perPage = 200, String? search}) async {
    // Sengaja TIDAK mengirim `startRow`/`endRow`: jalur "tradisional"
    // (`BukuService::getAllBuku`) adalah satu-satunya yang menyaring
    // `judul` / `isbn` / `penulis`. Jalur AG-Grid justru menyaring kolom
    // `nama` yang tidak ada di tabel `mst_buku`.
    final response = await _dio.get(
      '/perpustakaan/buku',
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _parseBuku(response.data);
  }

  @override
  Future<List<BukuModel>> getBukuAvailable() async {
    final response = await _dio.get('/perpustakaan/buku/available');
    return _parseBuku(response.data);
  }

  @override
  Future<BukuModel> getBukuDetail(int bukuId) async {
    final response = await _dio.get('/perpustakaan/buku/$bukuId');
    final raw = _extractObject(response.data);
    if (raw['id'] == null) {
      throw const NotFoundException('Detail buku tidak tersedia');
    }
    return BukuModel.fromJson(raw);
  }

  @override
  Future<BukuRiwayatModel> getRiwayatBuku(int bukuId) async {
    final response = await _dio.get('/perpustakaan/buku/$bukuId/peminjaman');

    // Backend mengirim `data: []` bila buku tidak ditemukan.
    final raw = response.data is Map ? (response.data as Map)['data'] : null;
    if (raw is! Map) {
      throw const NotFoundException('Riwayat peminjaman buku tidak tersedia');
    }
    return BukuRiwayatModel.fromJson(Map<String, dynamic>.from(raw));
  }

  // ── Peminjaman ─────────────────────────────────────────────────────────────

  @override
  Future<List<PeminjamanBukuModel>> getPeminjamanList({
    int perPage = 100,
  }) async {
    final response = await _dio.get(
      '/perpustakaan/peminjaman',
      queryParameters: <String, dynamic>{'per_page': perPage},
    );
    return _parsePeminjaman(response.data);
  }

  @override
  Future<List<PeminjamanBukuModel>> getPeminjamanBySiswa(int siswaId) async {
    final response = await _dio.get('/perpustakaan/peminjaman/siswa/$siswaId');
    return _parsePeminjaman(response.data);
  }

  @override
  Future<List<PeminjamanBukuModel>> getPeminjamanOverdue() async {
    final response = await _dio.get('/perpustakaan/peminjaman/overdue');
    return _parsePeminjaman(response.data);
  }

  @override
  Future<PeminjamanBukuModel> createPeminjaman({
    required int siswaId,
    required int bukuId,
    String? tanggalPinjam,
    required String tanggalJatuhTempo,
  }) async {
    // Field mengikuti `CreatePeminjamanBukuRequest` PERSIS.
    // `keterangan` sengaja tidak dikirim: kolomnya tidak ada di migrasi
    // `trx_peminjaman_buku` dan tidak masuk `$fillable`, jadi selalu diabaikan.
    final body = <String, dynamic>{
      'mst_siswa_id': siswaId,
      'mst_buku_id': bukuId,
      if (tanggalPinjam != null && tanggalPinjam.isNotEmpty)
        'tanggal_pinjam': tanggalPinjam,
      'tanggal_jatuh_tempo': tanggalJatuhTempo,
    };

    final response = await _dio.post('/perpustakaan/peminjaman', data: body);
    return PeminjamanBukuModel.fromJson(_extractObject(response.data));
  }

  @override
  Future<PeminjamanBukuModel> prosesPengembalian(int peminjamanId) async {
    final response = await _dio.post(
      '/perpustakaan/peminjaman/$peminjamanId/pengembalian',
    );
    return PeminjamanBukuModel.fromJson(_extractObject(response.data));
  }
}
