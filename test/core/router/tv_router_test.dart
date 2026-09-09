import 'package:akademihub_mob/core/di/injection.dart';
import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TV Routing and Platform Detection', () {
    test('initialLocation is /tv/bootstrap when isTv is true', () {
      final tvRouter = createAppRouter(isTv: true);
      expect(
        tvRouter.routeInformationProvider.value.uri.path,
        AppRoutes.tvBootstrap,
      );
    });

    test('initialLocation is / when isTv is false', () {
      final mobileRouter = createAppRouter(isTv: false);
      expect(
        mobileRouter.routeInformationProvider.value.uri.path,
        AppRoutes.splash,
      );
    });

    testWidgets('handset redirects deep link /tv/* to / (splash)', (tester) async {
      final mobileRouter = createAppRouter(isTv: false);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: mobileRouter,
        ),
      );
      await tester.pump();

      // Deep link to /tv/pairing on mobile handset
      mobileRouter.go(AppRoutes.tvPairing);
      await tester.pumpAndSettle();

      expect(
        mobileRouter.routeInformationProvider.value.uri.path,
        AppRoutes.splash,
      );
    });

    testWidgets('TV mode stays in /tv routes without mobile AuthBloc', (tester) async {
      final tvRouter = createAppRouter(isTv: true);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: tvRouter,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tvRouter.routeInformationProvider.value.uri.path,
        AppRoutes.tvBootstrap,
      );
      expect(find.byKey(const Key('tv_bootstrap_page')), findsOneWidget);

      // Navigate to tvPairing
      tvRouter.go(AppRoutes.tvPairing);
      await tester.pumpAndSettle();

      expect(
        tvRouter.routeInformationProvider.value.uri.path,
        AppRoutes.tvPairing,
      );
      expect(find.byKey(const Key('tv_pairing_page')), findsOneWidget);

      // Navigate to tvSignage
      tvRouter.go(AppRoutes.tvSignage);
      await tester.pumpAndSettle();

      expect(
        tvRouter.routeInformationProvider.value.uri.path,
        AppRoutes.tvSignage,
      );
      expect(find.byKey(const Key('tv_signage_page')), findsOneWidget);
    });

    testWidgets('TV mode redirects mobile routes back to /tv/bootstrap', (tester) async {
      final tvRouter = createAppRouter(isTv: true);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: tvRouter,
        ),
      );
      await tester.pumpAndSettle();

      // Attempt to access mobile dashboard directly
      tvRouter.go(AppRoutes.dashboard);
      await tester.pumpAndSettle();

      expect(
        tvRouter.routeInformationProvider.value.uri.path,
        AppRoutes.tvBootstrap,
      );
    });

    test('isTvDevice DI registration behaves correctly', () {
      setTvDeviceForTesting(true);
      expect(isTvDevice, isTrue);

      setTvDeviceForTesting(false);
      expect(isTvDevice, isFalse);
    });
  });
}
