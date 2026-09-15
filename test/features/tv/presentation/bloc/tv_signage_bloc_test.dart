import 'package:akademihub_mob/core/error/failures.dart';
import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/tv/data/models/tv_snapshot_model.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_pairing_session.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_snapshot.dart';
import 'package:akademihub_mob/features/tv/domain/repositories/tv_repository.dart';
import 'package:akademihub_mob/features/tv/presentation/bloc/tv_signage_bloc.dart';
import 'package:akademihub_mob/features/tv/presentation/bloc/tv_signage_event.dart';
import 'package:akademihub_mob/features/tv/presentation/bloc/tv_signage_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSignageRepo implements TvRepository {
  Result<TvSnapshot?> cachedResult = success(null);
  Result<TvSnapshotFetch> snapshotResult = const ResultFailure(
    NetworkFailure(),
  );
  bool unpairCalled = false;

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
      snapshotResult;
  @override
  Future<Result<TvSnapshot?>> readCachedSnapshot() async => cachedResult;
  @override
  Future<Result<void>> unpair() async {
    unpairCalled = true;
    return success(null);
  }
}

void main() {
  late _FakeSignageRepo repository;
  late TvSignageBloc bloc;
  late DateTime clock;

  final sampleSnapshot = TvSnapshotModel.fromJson({
    'generated_at': '2026-09-05T14:20:00Z',
    'refresh_after_seconds': 60,
    'device': {'id': 1, 'name': 'TV 1', 'mode': 'signage'},
    'school': {'name': 'SMA 1', 'timezone': 'Asia/Jakarta'},
    'settings': {'slide_duration_seconds': 10, 'show_attendance': true},
    'schedule': [
      {
        'id': 1,
        'subject': 'Fisika',
        'teacher': 'Pak Guru',
        'class': 'XII',
        'starts_at': '08:00',
        'ends_at': '09:30',
      },
    ],
    'announcements': [
      {
        'id': 1,
        'title': 'Lomba',
        'body': 'Daftar sekarang',
        'priority': 'normal',
      },
    ],
    'calendar': [
      {
        'id': 1,
        'title': 'UTS',
        'starts_at': '2026-09-10T00:00:00Z',
        'ends_at': '2026-09-15T00:00:00Z',
        'all_day': true,
      },
    ],
  });

  setUp(() {
    repository = _FakeSignageRepo();
    clock = DateTime.utc(2026, 9, 5, 14, 20);
    bloc = TvSignageBloc(repository: repository, now: () => clock);
  });

  tearDown(() => bloc.close());

  group('TvSignageBloc', () {
    test('active snapshot disappears at 24 hours, recovers with a full fetch', () async {
      repository.snapshotResult = success(TvSnapshotModified(sampleSnapshot, etag: '"fresh"'));
      bloc.add(const TvSignageStarted());
      await expectLater(bloc.stream, emitsThrough(isA<TvSignageReady>()));
      repository.snapshotResult = const ResultFailure(NetworkFailure());
      clock = clock.add(const Duration(hours: 24));
      bloc.add(const TvSignageCacheExpired());
      await expectLater(bloc.stream, emits(isA<TvSignageOffline>()));
      repository.snapshotResult = success(TvSnapshotModified(sampleSnapshot));
      bloc.add(const TvSignageRefreshRequested());
      await expectLater(bloc.stream, emits(isA<TvSignageReady>()));
    });

    test('cache older than 24 hours is never rendered on startup', () async {
      repository.cachedResult = success(sampleSnapshot);
      clock = clock.add(const Duration(hours: 25));
      final check = expectLater(bloc.stream, emitsInOrder([const TvSignageLoading(), isA<TvSignageOffline>()]));
      bloc.add(const TvSignageStarted());
      await check;
    });
    test('initial state is TvSignageInitial', () {
      expect(bloc.state, const TvSignageInitial());
    });

    test(
      'TvSignageStarted emits loading then ready on fresh network snapshot',
      () async {
        repository.snapshotResult = success(
          TvSnapshotModified(sampleSnapshot, etag: '"etag1"'),
        );

        expectLater(
          bloc.stream,
          emitsInOrder([
            const TvSignageLoading(),
            isA<TvSignageReady>()
                .having((s) => s.isOffline, 'isOffline', false)
                .having((s) => s.snapshot.school.name, 'school', 'SMA 1'),
          ]),
        );

        bloc.add(const TvSignageStarted());
      },
    );

    test(
      'TvSignageStarted emits cached snapshot first, then updates from network',
      () async {
        repository.cachedResult = success(sampleSnapshot);
        repository.snapshotResult = success(
          TvSnapshotModified(sampleSnapshot, etag: '"etag2"'),
        );

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<TvSignageReady>().having((s) => s.isOffline, 'isOffline', true),
            isA<TvSignageReady>().having(
              (s) => s.isOffline,
              'isOffline',
              false,
            ),
          ]),
        );

        bloc.add(const TvSignageStarted());
      },
    );

    test(
      'TvSignageNextSlideTicked rotates currentSlideIndex modulo total slides',
      () async {
        repository.snapshotResult = success(TvSnapshotModified(sampleSnapshot));
        bloc.add(const TvSignageStarted());

        await expectLater(bloc.stream, emitsThrough(isA<TvSignageReady>()));
        expect((bloc.state as TvSignageReady).currentSlideIndex, 0);

        bloc.add(const TvSignageNextSlideTicked());
        await expectLater(
          bloc.stream,
          emits(
            isA<TvSignageReady>().having(
              (s) => s.currentSlideIndex,
              'slideIndex',
              1,
            ),
          ),
        );

        bloc.add(const TvSignageNextSlideTicked());
        await expectLater(
          bloc.stream,
          emits(
            isA<TvSignageReady>().having(
              (s) => s.currentSlideIndex,
              'slideIndex',
              2,
            ),
          ),
        );

        bloc.add(const TvSignageNextSlideTicked());
        await expectLater(
          bloc.stream,
          emits(
            isA<TvSignageReady>().having(
              (s) => s.currentSlideIndex,
              'slideIndex',
              0,
            ),
          ),
        );
      },
    );

    test('AuthFailure emits TvSignageAuthExpired', () async {
      repository.snapshotResult = const ResultFailure(
        AuthFailure('Token invalid'),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([const TvSignageLoading(), const TvSignageAuthExpired()]),
      );

      bloc.add(const TvSignageStarted());
    });

    test(
      'TvSignageUnpairConfirmed calls unpair and emits TvSignageAuthExpired',
      () async {
        bloc.add(const TvSignageUnpairConfirmed());

        await expectLater(bloc.stream, emits(const TvSignageAuthExpired()));

        expect(repository.unpairCalled, isTrue);
      },
    );
  });
}
