import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PPDB route is public and has no permission requirement', () {
    expect(AppRoutes.isPublicPath(AppRoutes.ppdb), isTrue);
    expect(AppRoutes.permissionsFor(AppRoutes.ppdb), isEmpty);
  });
}
