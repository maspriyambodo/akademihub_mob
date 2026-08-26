import 'package:akademihub_mob/features/wali/guardian_child_selector.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads authoritative children once per wali', () async {
    final dio = Dio();
    var calls = 0;
    dio.httpClientAdapter = _Adapter((options) {
      calls++;
      expect(options.path, '/wali/7/siswa');
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":12,"nama":"Alya","kelas":{"id":4}}]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final service = GuardianChildService(dio);
    final first = await service.getChildren(7);
    final second = await service.getChildren(7);
    expect(calls, 1);
    expect(first.single.id, 12);
    expect(second.single.kelasId, 4);
  });
}

class _Adapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) handler;
  _Adapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? stream,
    Future<void>? cancel,
  ) async => handler(options);
  @override
  void close({bool force = false}) {}
}
