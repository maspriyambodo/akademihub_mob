import 'package:akademihub_mob/features/organisasi/data/organisasi_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses only read endpoints', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()..httpClientAdapter = _Adapter(requests);
    final source = OrganisasiRemoteDataSource(dio);

    await source.list();
    await source.detail(7);
    await source.anggota(7);

    expect(requests.map((request) => request.method), everyElement('GET'));
    expect(requests.map((request) => request.path), [
      '/organisasi',
      '/organisasi/7',
      '/organisasi/anggota/organisasi/7',
    ]);
  });
}

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests;
  _Adapter(this.requests);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('{"data":[]}', 200);
  }

  @override
  void close({bool force = false}) {}
}
