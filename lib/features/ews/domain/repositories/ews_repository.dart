import '../../../../core/error/result.dart';
import '../entities/ews_alert_entity.dart';

abstract class EwsRepository {
  /// Ambil daftar alert EWS.
  ///
  /// Endpoint: `GET /api/v1/ews`.
  /// Filter query opsional: `mst_siswa_id`, `kategori`, `level`, `is_resolved`.
  Future<Result<List<EwsAlertEntity>>> getAlerts({
    int? siswaId,
    String? kategori,
    int? level,
    bool? isResolved,
  });

  /// Ambil detail satu alert.
  ///
  /// Endpoint: `GET /api/v1/ews/{id}`.
  Future<Result<EwsAlertEntity>> getAlertDetail(int id);

  /// Tandai alert selesai.
  ///
  /// Endpoint: `PUT /api/v1/ews/{id}/resolve`.
  Future<Result<void>> resolveAlert(int id);

  /// Trigger pengecekan EWS manual untuk satu siswa.
  ///
  /// Endpoint: `POST /api/v1/ews/{siswaId}/trigger`.
  Future<Result<void>> triggerCheck(int siswaId);
}
