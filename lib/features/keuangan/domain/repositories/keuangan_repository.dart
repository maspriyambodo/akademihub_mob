import '../../../../core/error/result.dart';
import '../entities/laporan_periode_entity.dart';
import '../entities/pembayaran_online_entity.dart';
import '../entities/pembayaran_spp_entity.dart';
import '../entities/status_pembayaran_entity.dart';
import '../entities/tarif_spp_entity.dart';
import '../entities/tunggakan_entity.dart';

abstract class KeuanganRepository {
  // ── Pembayaran SPP ────────────────────────────────────────────────────────

  /// Daftar pembayaran umum (admin/petugas/guru/wali).
  /// Backend sudah memfilter visibilitas per sesi
  /// (`PembayaranSppService::applySessionVisibilityFilter`).
  ///
  /// [search] mencari nama & NIS siswa, tahun, dan keterangan — HANYA berfungsi
  /// bila request dikirim dalam mode AG-Grid (`startRow`/`endRow`), lihat
  /// datasource.
  Future<Result<List<PembayaranSppEntity>>> getPembayaranList({
    String? search,
    int? tahun,
    int? bulan,
    String? status,
  });

  /// Detail satu tagihan/pembayaran.
  Future<Result<PembayaranSppEntity>> getPembayaranDetail(int id);

  /// Riwayat + tagihan SPP milik satu siswa (urut tahun & bulan menurun).
  Future<Result<List<PembayaranSppEntity>>> getPembayaranBySiswa(int siswaId);

  /// Ringkasan status pembayaran satu siswa dalam satu tahun ajaran.
  /// [tahunAjaran] berformat "2026/2027"; backend hanya memakai 4 digit awal.
  Future<Result<StatusPembayaranEntity>> getStatusPembayaran(
    int siswaId, {
    String? tahunAjaran,
  });

  /// Rekap tunggakan + denda per bulan. `tarifSppId` dan `tahun` WAJIB.
  Future<Result<List<TunggakanEntity>>> getTunggakan({
    required int siswaId,
    required int tarifSppId,
    required int tahun,
  });

  /// Kalkulasi denda keterlambatan satu bulan.
  Future<Result<DendaEntity>> hitungDenda({
    required int tarifSppId,
    required int bulan,
    required int tahun,
    String? tanggalBayar,
  });

  /// Laporan keuangan SPP per periode (admin/petugas).
  Future<Result<LaporanPeriodeEntity>> getLaporanPeriode({
    int? tahun,
    int? bulanDari,
    int? bulanSampai,
    int? kelasId,
    int? tahunAjaranId,
  });

  // ── Tarif SPP ─────────────────────────────────────────────────────────────

  Future<Result<List<TarifSppEntity>>> getTarifList({String? search});

  Future<Result<TarifSppEntity>> getTarifDetail(int id);

  /// Tarif SPP satu kelas. Mengembalikan `NotFoundFailure` bila kelas belum
  /// punya tarif untuk tahun ajaran tersebut.
  Future<Result<TarifSppEntity>> getTarifByKelas(
    int kelasId, {
    int? tahunAjaranId,
  });

  // ── Aksi tulis (butuh permission `pembayaran-spp.bayar`) ──────────────────

  /// Catat pembayaran satu bulan (aksi admin/petugas).
  /// [status] & [metodePembayaran] memakai KODE angka `sys_references`
  /// (status: 1=Lunas, 2=Belum Lunas, 3=Pending, 4=Batal;
  /// metode: 1=Tunai, 2=Transfer, 3=Virtual Account).
  Future<Result<PembayaranSppEntity>> bayarSpp({
    required int siswaId,
    required int tarifSppId,
    required int bulan,
    required int tahun,
    required double jumlahBayar,
    String? tanggalBayar,
    int? status,
    int? metodePembayaran,
    String? keterangan,
  });

  /// Catat pembayaran beberapa bulan sekaligus (aksi admin/petugas).
  Future<Result<List<PembayaranSppEntity>>> bayarMultiple({
    required int siswaId,
    required int tarifSppId,
    required List<int> bulan,
    required int tahun,
    double? jumlahBayarPerBulan,
    String? tanggalBayar,
    String? metodePembayaran,
    String? keterangan,
  });

  /// Inisiasi pembayaran online (Midtrans SNAP) satu bulan.
  Future<Result<PembayaranOnlineEntity>> bayarOnline({
    required int siswaId,
    required int tarifSppId,
    required int bulan,
    required int tahun,
  });
}
