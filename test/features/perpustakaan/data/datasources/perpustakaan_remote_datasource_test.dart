import 'package:akademihub_mob/features/perpustakaan/data/datasources/perpustakaan_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses only scoped read-only library routes', () async {
    final adapter = _RecordingAdapter();
    final source = PerpustakaanRemoteDataSource(
      Dio()..httpClientAdapter = adapter,
    );
    await source.availableBooks();
    await source.loansForStudent(42);
    expect(adapter.requests, [
      '/perpustakaan/buku/available',
      '/perpustakaan/peminjaman/siswa/42',
    ]);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <String>[];
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.path);
    expect(options.method, 'GET');
    return ResponseBody.fromString(
      '{"data":[]}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
