import 'package:akademihub_mob/core/error/failures.dart';
import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_pairing_session.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_snapshot.dart';
import 'package:akademihub_mob/features/tv/domain/repositories/tv_repository.dart';
import 'package:akademihub_mob/features/tv/presentation/bloc/tv_auth_bloc.dart';
import 'package:akademihub_mob/features/tv/presentation/bloc/tv_auth_event.dart';
import 'package:akademihub_mob/features/tv/presentation/bloc/tv_auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTvRepository implements TvRepository {
  bool hasToken = false;
  Result<TvPairingSession>? createSessionResult;
  Result<TvPairingStatus>? pairingStatusResult;
  bool unpairCalled = false;

  @override
  Future<bool> hasDeviceToken() async => hasToken;

  @override
  Future<Result<TvPairingSession>> createPairingSession() async {
    return createSessionResult ??
        success(
          TvPairingSession(
            sessionId: 'sess-1',
            userCode: 'AB7K9Q',
            verificationUrl: 'https://app.akademihub.id/tv-pair',
            expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
            pollInterval: const Duration(seconds: 3),
          ),
        );
  }

  @override
  Future<Result<TvPairingStatus>> getPairingStatus(String sessionId) async {
    return pairingStatusResult ??
        success(const TvPairingStatus(state: TvPairingState.pending));
  }

  @override
  Future<Result<TvSnapshotFetch>> getSnapshot({String? etag}) async {
    return const ResultFailure(ServerFailure('not implemented'));
  }

  @override
  Future<Result<TvSnapshot?>> readCachedSnapshot() async {
    return success(null);
  }

  @override
  Future<Result<void>> unpair() async {
    unpairCalled = true;
    hasToken = false;
    return success(null);
  }
}

void main() {
  late FakeTvRepository repository;
  late TvAuthBloc bloc;

  setUp(() {
    repository = FakeTvRepository();
    bloc = TvAuthBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('TvAuthBloc', () {
    test('initial state is TvAuthInitial', () {
      expect(bloc.state, const TvAuthInitial());
    });

    test(
      'TvAuthStarted emits [TvAuthChecking, TvAuthPaired] when token exists',
      () async {
        repository.hasToken = true;

        final expected = [const TvAuthChecking(), const TvAuthPaired()];

        expectLater(bloc.stream, emitsInOrder(expected));
        bloc.add(const TvAuthStarted());
      },
    );

    test(
      'TvAuthStarted emits [TvAuthChecking, TvPairingLoading, TvPairingPending] when no token',
      () async {
        repository.hasToken = false;

        final expected = [
          const TvAuthChecking(),
          const TvPairingLoading(),
          isA<TvPairingPending>(),
        ];

        expectLater(bloc.stream, emitsInOrder(expected));
        bloc.add(const TvAuthStarted());
      },
    );

    test(
      'TvPairingPollTicked emits TvAuthPaired when status is approved',
      () async {
        repository.createSessionResult = success(
          TvPairingSession(
            sessionId: 'sess-1',
            userCode: 'AB7K9Q',
            verificationUrl: 'https://app.akademihub.id/tv-pair',
            expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
            pollInterval: const Duration(seconds: 3),
          ),
        );

        bloc.add(const TvPairingRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([const TvPairingLoading(), isA<TvPairingPending>()]),
        );

        repository.pairingStatusResult = success(
          const TvPairingStatus(
            state: TvPairingState.approved,
            deviceId: 42,
            deviceName: 'TV Lobby',
            deviceMode: 'signage',
          ),
        );

        bloc.add(const TvPairingPollTicked());
        await expectLater(
          bloc.stream,
          emits(const TvAuthPaired(deviceId: 42, deviceMode: 'signage')),
        );
      },
    );

    test(
      'TvPairingPollTicked emits TvPairingDenied when status is denied',
      () async {
        bloc.add(const TvPairingRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([const TvPairingLoading(), isA<TvPairingPending>()]),
        );

        repository.pairingStatusResult = success(
          const TvPairingStatus(state: TvPairingState.denied),
        );

        bloc.add(const TvPairingPollTicked());
        await expectLater(bloc.stream, emits(isA<TvPairingDenied>()));
      },
    );

    test(
      'TvPairingPollTicked emits TvPairingExpired when session is expired',
      () async {
        repository.createSessionResult = success(
          TvPairingSession(
            sessionId: 'sess-1',
            userCode: 'AB7K9Q',
            verificationUrl: 'https://app.akademihub.id/tv-pair',
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            ),
            pollInterval: const Duration(seconds: 3),
          ),
        );

        bloc.add(const TvPairingRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([const TvPairingLoading(), isA<TvPairingPending>()]),
        );

        bloc.add(const TvPairingPollTicked());
        await expectLater(bloc.stream, emits(isA<TvPairingExpired>()));
      },
    );

    test(
      'TvUnpairRequested calls unpair and requests new pairing session',
      () async {
        bloc.add(const TvUnpairRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([const TvPairingLoading(), isA<TvPairingPending>()]),
        );

        expect(repository.unpairCalled, isTrue);
      },
    );
  });
}
