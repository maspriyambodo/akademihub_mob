import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/kalender_event_entity.dart';
import '../entities/kalender_harian_entity.dart';
import '../entities/kalender_konteks_entity.dart';
import '../entities/kalender_tipe_entity.dart';

/// Kegagalan khusus modul kalender: backend membalas 403 karena user tidak
/// punya permission yang dibutuhkan (mis. `kalender-akademik.view`).
///
/// `core/error/failures.dart` belum punya varian "forbidden" dan file core
/// tidak boleh disentuh dari fitur, jadi varian ini didefinisikan lokal.
class KalenderAccessFailure extends Failure {
  const KalenderAccessFailure([
    super.message =
        'Anda tidak memiliki izin untuk melihat kalender akademik.',
  ]);
}

abstract class KalenderRepository {
  /// Daftar event kalender akademik, terbaru lebih dulu.
  /// Butuh permission `kalender-akademik.view`.
  Future<Result<List<KalenderEventEntity>>> getEvents({int limit});

  /// Daftar agenda harian beserta event induknya.
  /// Butuh permission `kalender-harian.view`.
  Future<Result<List<KalenderHarianEntity>>> getHarian({int limit});

  /// Master tipe/kategori event. Butuh permission `kalender-tipe.view`.
  Future<Result<List<KalenderTipeEntity>>> getTipeList();

  /// Konteks akademik (tahun ajaran aktif, semester aktif, hari operasional).
  ///
  /// Bersifat "best effort": setiap bagian yang gagal / tidak diizinkan
  /// dibiarkan kosong, sehingga pemanggilnya tidak pernah menerima kegagalan.
  Future<Result<KalenderKonteksEntity>> getKonteks();
}
