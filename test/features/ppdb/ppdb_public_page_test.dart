import 'dart:typed_data';

import 'package:akademihub_mob/core/theme/app_theme.dart';
import 'package:akademihub_mob/features/ppdb/presentation/pages/ppdb_public_page.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires school, wave, gender, and four documents', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio()..httpClientAdapter = _Adapter();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PpdbPublicPage(dio: dio),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama lengkap'),
      'Alya',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'alya@example.test',
    );
    await tester.tap(find.byKey(const Key('ppdb-register')).last);
    await tester.pump();

    expect(
      find.text('Pilih sekolah, gelombang, dan jenis kelamin.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects document above 2 MB', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio()..httpClientAdapter = _Adapter();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PpdbPublicPage(
          dio: dio,
          pickFile: () async => PlatformFile(
            name: 'large.pdf',
            size: 2 * 1024 * 1024 + 1,
            bytes: Uint8List(1),
          ),
        ),
      ),
    );
    await tester.pump();

    final upload = find
        .widgetWithText(OutlinedButton, 'Unggah Kartu Keluarga')
        .last;
    await tester.tap(upload);
    await tester.pumpAndSettle();

    expect(find.text('Ukuran setiap berkas maksimal 2 MB.'), findsOneWidget);
  });
}

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => ResponseBody.fromString('{"success":true,"data":[]}', 200);

  @override
  void close({bool force = false}) {}
}
