import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every registered route has an explicit policy', () {
    for (final path in [
      ...AppRoutes.registeredPaths,
      ...AppRoutes.ewsAliases,
    ]) {
      final concretePath = path == AppRoutes.siswaInsight
          ? '/siswa/42/insight'
          : path;
      expect(
        AppRoutes.policyFor(concretePath),
        isNotNull,
        reason: '$path must fail closed through an explicit route policy',
      );
    }
  });

  test(
    'every protected route denies missing permission and allows a match',
    () {
      for (final path in [
        ...AppRoutes.registeredPaths,
        ...AppRoutes.ewsAliases,
      ]) {
        final concretePath = path == AppRoutes.siswaInsight
            ? '/siswa/42/insight'
            : path;
        final policy = AppRoutes.policyFor(concretePath)!;
        if (policy.access != RouteAccess.permissionAny) continue;

        expect(
          AppRoutes.canAccess(concretePath, authenticated: true),
          isFalse,
          reason: '$path must deny an authenticated user without permission',
        );
        expect(
          AppRoutes.canAccess(
            concretePath,
            authenticated: true,
            permissions: [policy.permissions.first],
          ),
          isTrue,
          reason: '$path must allow a matching permission',
        );
      }
    },
  );

  test('sensitive module routes require backend permissions', () {
    expect(AppRoutes.permissionsFor(AppRoutes.rapor), ['rapor.view']);
    expect(AppRoutes.permissionsFor(AppRoutes.keuangan), [
      'pembayaran-spp.view',
    ]);
    expect(AppRoutes.permissionsFor(AppRoutes.forum), ['forum.view']);
    expect(AppRoutes.permissionsFor(AppRoutes.ekstrakurikuler), [
      'ekstrakurikuler.view',
    ]);
  });

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
