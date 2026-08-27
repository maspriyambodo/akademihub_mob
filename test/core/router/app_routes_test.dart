import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only bootstrap routes are public', () {
    expect(AppRoutes.isPublicPath(AppRoutes.splash), isTrue);
    expect(AppRoutes.isPublicPath(AppRoutes.login), isTrue);
    expect(AppRoutes.isPublicPath('/ppdb'), isFalse);
  });

  test('unknown routes fail closed', () {
    expect(AppRoutes.canAccess('/unknown', authenticated: true), isFalse);
  });
}
