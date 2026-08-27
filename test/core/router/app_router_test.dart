import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires siswa.view for student insight', () {
    expect(AppRoutes.permissionsFor('/siswa/42/insight'), ['siswa.view']);
  });

  test('requires organisasi.view for organisasi route', () {
    expect(AppRoutes.permissionsFor(AppRoutes.organisasi), ['organisasi.view']);
  });

  test('requires materi.view for materi', () {
    expect(AppRoutes.permissionsFor(AppRoutes.materi), ['materi.view']);
  });

  test('requires a verified library read permission', () {
    expect(AppRoutes.permissionsFor(AppRoutes.perpustakaan), [
      'buku.view',
      'peminjaman.view',
    ]);
  });

  test('permission route allows matching permission and denies others', () {
    expect(
      AppRoutes.canAccess(
        AppRoutes.materi,
        authenticated: true,
        permissions: const ['materi.view'],
      ),
      isTrue,
    );
    expect(AppRoutes.canAccess(AppRoutes.materi, authenticated: true), isFalse);
  });

  test('authenticated route has explicit policy', () {
    expect(
      AppRoutes.policyFor(AppRoutes.profil)?.access,
      RouteAccess.authenticated,
    );
    expect(AppRoutes.canAccess(AppRoutes.profil, authenticated: true), isTrue);
    expect(
      AppRoutes.canAccess(AppRoutes.profil, authenticated: false),
      isFalse,
    );
  });

  test('EWS aliases inherit EWS permission', () {
    for (final alias in AppRoutes.ewsAliases) {
      expect(AppRoutes.permissionsFor(alias), ['ews.view']);
    }
  });
}
