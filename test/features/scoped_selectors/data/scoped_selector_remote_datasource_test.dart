import 'package:akademihub_mob/features/scoped_selectors/data/datasources/scoped_selector_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _Adapter adapter;
  late ScopedSelectorRemoteDataSource source;

  setUp(() {
    adapter = _Adapter();
    source = ScopedSelectorRemoteDataSourceImpl(
      Dio()..httpClientAdapter = adapter,
    );
  });

  test('uses self-scoped guru-mapel route', () async {
    final items = await source.getGuruMapelSaya();
    expect(adapter.path, '/guru-mapel/saya');
    expect(items.single.mapelNama, 'Matematika');
  });

  test('uses authorized class routes and models nested students', () async {
    await source.getKelasAccessible(waliGuruId: 7);
    expect(adapter.path, '/kelas');
    expect(adapter.query['wali_guru_id'], 7);

    final siswa = await source.getSiswaByKelas(4);
    expect(adapter.path, '/kelas/4/siswa');
    expect(siswa.single.nis, '2026001');
  });

  test('loads exams and semesters by backend routes', () async {
    final ujian = await source.getUjianByKelas(4);
    expect(adapter.path, '/akademik/ujian/kelas/4');
    expect(ujian.single.nama, 'PTS');

    final semester = await source.getSemester();
    expect(adapter.path, '/admin/semester');
    expect(semester.single.tahunAjaranId, 2);
  });
}

class _Adapter implements HttpClientAdapter {
  String? path;
  Map<String, dynamic> query = const {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    query = options.queryParameters;
    final body = switch (options.path) {
      '/guru-mapel/saya' =>
        '{"data":[{"id":1,"mst_guru_id":7,"mst_mapel_id":3,"mapel":{"nama":"Matematika"}}]}',
      '/kelas/4/siswa' =>
        '{"data":{"siswa":[{"id":9,"nama":"Budi","nis":"2026001"}]}}',
      '/akademik/ujian/kelas/4' => '{"data":[{"id":8,"nama":"PTS"}]}',
      '/admin/semester' =>
        '{"data":[{"id":5,"nama":"Ganjil","tahun_ajaran_id":2}]}',
      _ => '{"data":[{"id":4,"nama_kelas":"X-A"}]}',
    };
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
