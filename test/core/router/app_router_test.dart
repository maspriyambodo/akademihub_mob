import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires siswa.view for student insight', () {
    expect(AppRoutes.permissionsFor('/siswa/42/insight'), ['siswa.view']);
  });
}
