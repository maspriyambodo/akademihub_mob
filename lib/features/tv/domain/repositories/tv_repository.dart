import '../../../../core/error/result.dart';
import '../entities/tv_pairing_session.dart';
import '../entities/tv_snapshot.dart';

abstract class TvRepository {
  Future<Result<TvPairingSession>> createPairingSession();
  Future<Result<TvPairingStatus>> getPairingStatus(String sessionId);
  Future<Result<TvSnapshotFetch>> getSnapshot({String? etag});
  Future<Result<TvSnapshot?>> readCachedSnapshot();
  Future<Result<void>> unpair();
  Future<bool> hasDeviceToken();
}
