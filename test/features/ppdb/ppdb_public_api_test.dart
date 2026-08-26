import 'dart:typed_data';

import 'package:akademihub_mob/features/ppdb/data/ppdb_public_api.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('register posts contract fields and four multipart documents', () async {
    final dio = Dio();
    dio.httpClientAdapter = _Adapter((options) {
      expect(options.path, '/ppdb/public/daftar');
      expect(options.method, 'POST');
      final body = options.data as FormData;
      final fields = Map<String, dynamic>.fromEntries(body.fields);
      expect(fields['mst_sekolah_id'].toString(), '1');
      expect(fields['ppdb_gelombang_id'].toString(), '2');
      expect(fields['jenis_kelamin'], 'L');
      expect(body.files.map((entry) => entry.key), {
        'kartukeluarga',
        'akte',
        'rapor',
        'ijazah',
      });
      return ResponseBody.fromString(
        '{"success":true,"data":{"no_pendaftaran":"PPDB-001","status_pendaftaran":"menunggu"}}',
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    final result = await PpdbPublicApi(dio).register(
      fields: {
        'mst_sekolah_id': 1,
        'ppdb_gelombang_id': 2,
        'nama_lengkap': 'Alya',
        'email': 'alya@example.test',
        'jenis_kelamin': 'L',
      },
      documents: {
        for (final key in ['kartukeluarga', 'akte', 'rapor', 'ijazah'])
          key: PlatformFile(name: '$key.pdf', size: 1, bytes: Uint8List(1)),
      },
    );

    expect(result['data']['no_pendaftaran'], 'PPDB-001');
  });
}

class _Adapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) handler;
  _Adapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}
