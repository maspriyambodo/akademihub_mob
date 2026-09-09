import 'package:akademihub_mob/core/di/injection.dart';
import 'package:akademihub_mob/core/error/failures.dart';
import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_pairing_session.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_snapshot.dart';
import 'package:akademihub_mob/features/tv/domain/repositories/tv_repository.dart';
import 'package:akademihub_mob/features/tv/presentation/bloc/tv_auth_bloc.dart';
import 'package:akademihub_mob/features/tv/presentation/pages/tv_pairing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTvRepo implements TvRepository {
  @override
  Future<bool> hasDeviceToken() async => false;

  @override
  Future<Result<TvPairingSession>> createPairingSession() async {
    return success(
      TvPairingSession(
        sessionId: 'sess-abc',
        userCode: 'XK99ZZ',
        verificationUrl: 'https://app.akademihub.id/tv-pair',
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
        pollInterval: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Future<Result<TvPairingStatus>> getPairingStatus(String sessionId) async {
    return success(const TvPairingStatus(state: TvPairingState.pending));
  }

  @override
  Future<Result<TvSnapshotFetch>> getSnapshot({String? etag}) async =>
      ResultFailure(const NetworkFailure());

  @override
  Future<Result<TvSnapshot?>> readCachedSnapshot() async => success(null);

  @override
  Future<Result<void>> unpair() async => success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    if (sl.isRegistered<TvAuthBloc>()) {
      sl.unregister<TvAuthBloc>();
    }
    sl.registerFactory<TvAuthBloc>(() => TvAuthBloc(repository: _FakeTvRepo()));
  });

  tearDown(() {
    if (sl.isRegistered<TvAuthBloc>()) {
      sl.unregister<TvAuthBloc>();
    }
  });

  group('TvPairingPage', () {
    testWidgets('renders user pairing code and instructions', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TvPairingPage()));

      // Initial loading state
      expect(find.byKey(const Key('tv_pairing_page')), findsOneWidget);

      // Settle after async createPairingSession
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('XK99ZZ'), findsOneWidget);
      expect(find.textContaining('HUBUNGKAN LAYAR ANDROID TV'), findsOneWidget);
      expect(
        find.textContaining('https://app.akademihub.id/tv-pair'),
        findsOneWidget,
      );
      expect(find.text('Menunggu persetujuan admin...'), findsOneWidget);
    });
  });
}
