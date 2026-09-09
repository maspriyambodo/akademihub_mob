import 'package:akademihub_mob/core/di/injection.dart';
import 'package:akademihub_mob/core/error/failures.dart';
import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/tv/data/models/tv_snapshot_model.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_pairing_session.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_snapshot.dart';
import 'package:akademihub_mob/features/tv/domain/repositories/tv_repository.dart';
import 'package:akademihub_mob/features/tv/presentation/bloc/tv_signage_bloc.dart';
import 'package:akademihub_mob/features/tv/presentation/pages/tv_signage_page.dart';
import 'package:akademihub_mob/features/tv/presentation/widgets/tv_clock_header.dart';
import 'package:akademihub_mob/features/tv/presentation/widgets/tv_settings_dialog.dart';
import 'package:akademihub_mob/features/tv/presentation/widgets/tv_status_badge.dart';
import 'package:akademihub_mob/features/tv/presentation/widgets/tv_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTvRepoForPage implements TvRepository {
  final TvSnapshot snapshot;
  _FakeTvRepoForPage(this.snapshot);

  @override
  Future<bool> hasDeviceToken() async => true;
  @override
  Future<Result<TvPairingSession>> createPairingSession() async =>
      const ResultFailure(ServerFailure(''));
  @override
  Future<Result<TvPairingStatus>> getPairingStatus(String sessionId) async =>
      const ResultFailure(ServerFailure(''));
  @override
  Future<Result<TvSnapshotFetch>> getSnapshot({String? etag}) async =>
      success(TvSnapshotModified(snapshot));
  @override
  Future<Result<TvSnapshot?>> readCachedSnapshot() async => success(null);
  @override
  Future<Result<void>> unpair() async => success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleSnapshot = TvSnapshotModel.fromJson({
    'generated_at': '2026-09-05T14:20:00Z',
    'refresh_after_seconds': 60,
    'device': {'id': 99, 'name': 'TV Lobby Display', 'mode': 'signage'},
    'school': {'name': 'SMAN 1 Teladan', 'timezone': 'Asia/Jakarta'},
    'settings': {'slide_duration_seconds': 10, 'show_attendance': true},
    'schedule': [
      {
        'id': 1,
        'subject': 'Biologi Terapan',
        'teacher': 'Dr. Siti',
        'class': 'XI A',
        'starts_at': '07:30',
        'ends_at': '09:00',
      },
    ],
    'announcements': [
      {
        'id': 1,
        'title': 'Lomba Robotik Nasional',
        'body': 'Pendaftaran di lab fisika.',
        'priority': 'urgent',
      },
    ],
    'calendar': [],
  });

  setUp(() {
    if (sl.isRegistered<TvSignageBloc>()) {
      sl.unregister<TvSignageBloc>();
    }
    sl.registerFactory<TvSignageBloc>(
      () => TvSignageBloc(repository: _FakeTvRepoForPage(sampleSnapshot)),
    );
  });

  tearDown(() {
    if (sl.isRegistered<TvSignageBloc>()) {
      sl.unregister<TvSignageBloc>();
    }
  });

  group('TvSignagePage', () {
    testWidgets(
      'renders clock header, status badge, slide schedule, and ticker',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TvSignagePage()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(TvClockHeader), findsOneWidget);
        expect(find.byType(TvStatusBadge), findsOneWidget);
        expect(find.byType(TvTicker), findsOneWidget);
        expect(find.text('SMAN 1 Teladan'), findsOneWidget);
        expect(find.text('Biologi Terapan'), findsOneWidget);
        expect(find.textContaining('Lomba Robotik Nasional'), findsOneWidget);
      },
    );

    testWidgets('opens settings dialog when settings button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TvSignagePage()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find Settings button in header
      final settingsBtn = find.byIcon(Icons.settings);
      expect(settingsBtn, findsOneWidget);
      await tester.tap(settingsBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TvSettingsDialog), findsOneWidget);
      expect(find.text('Pengaturan Perangkat TV'), findsOneWidget);
      expect(find.text('TV Lobby Display'), findsOneWidget);
      expect(find.text('Putuskan Tautan Layar'), findsOneWidget);
    });

    testWidgets('renders without overflow on 1280x720 (720p)', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: TvSignagePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(TvSignagePage), findsOneWidget);
    });

    testWidgets('renders without overflow on 1920x1080 (1080p)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: TvSignagePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(TvSignagePage), findsOneWidget);
    });
  });
}
