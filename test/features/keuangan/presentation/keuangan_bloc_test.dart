import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/keuangan/domain/entities/laporan_periode_entity.dart';
import 'package:akademihub_mob/features/keuangan/domain/entities/pembayaran_online_entity.dart';
import 'package:akademihub_mob/features/keuangan/domain/entities/pembayaran_spp_entity.dart';
import 'package:akademihub_mob/features/keuangan/domain/entities/status_pembayaran_entity.dart';
import 'package:akademihub_mob/features/keuangan/domain/entities/tarif_spp_entity.dart';
import 'package:akademihub_mob/features/keuangan/domain/entities/tunggakan_entity.dart';
import 'package:akademihub_mob/features/keuangan/domain/repositories/keuangan_repository.dart';
import 'package:akademihub_mob/features/keuangan/domain/usecases/bayar_spp_usecase.dart';
import 'package:akademihub_mob/features/keuangan/domain/usecases/get_laporan_periode_usecase.dart';
import 'package:akademihub_mob/features/keuangan/domain/usecases/get_pembayaran_spp_usecase.dart';
import 'package:akademihub_mob/features/keuangan/domain/usecases/get_status_pembayaran_usecase.dart';
import 'package:akademihub_mob/features/keuangan/domain/usecases/get_tarif_spp_usecase.dart';
import 'package:akademihub_mob/features/keuangan/presentation/bloc/keuangan_aksi_status.dart';
import 'package:akademihub_mob/features/keuangan/presentation/bloc/keuangan_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'siswa cannot dispatch cash settlement despite bayar permission',
    () async {
      final repo = _KeuanganRepository();
      final bloc = KeuanganBloc(
        getPembayaranList: GetPembayaranListUseCase(repo),
        getPembayaranBySiswa: GetPembayaranBySiswaUseCase(repo),
        getStatusPembayaran: GetStatusPembayaranUseCase(repo),
        getTunggakan: GetTunggakanUseCase(repo),
        getTarifByKelas: GetTarifSppByKelasUseCase(repo),
        getLaporanPeriode: GetLaporanPeriodeUseCase(repo),
        bayarOnline: BayarOnlineSppUseCase(repo),
        bayarMultiple: BayarMultipleSppUseCase(repo),
      );
      final loaded = bloc.stream.firstWhere((state) => state is KeuanganLoaded);
      bloc.add(
        const KeuanganLoadRequested(
          role: 'siswa',
          profileId: 1,
          canBayar: true,
        ),
      );
      await loaded;

      final rejected = bloc.stream.firstWhere(
        (state) =>
            state is KeuanganLoaded &&
            state.aksiStatus == KeuanganAksiStatus.failure,
      );
      bloc.add(
        const KeuanganBayarMultipleRequested(bulan: [1, 2], tahun: 2026),
      );

      expect(
        (await rejected as KeuanganLoaded).aksiMessage,
        contains('pembayaran online'),
      );
      expect(repo.bayarMultipleCalls, 0);
      await bloc.close();
    },
  );
}

class _KeuanganRepository implements KeuanganRepository {
  int bayarMultipleCalls = 0;

  @override
  Future<Result<List<PembayaranSppEntity>>> getPembayaranBySiswa(
    int siswaId,
  ) async =>
      success([const PembayaranSppEntity(id: 1, siswaId: 1, tarifSppId: 2)]);

  @override
  Future<Result<List<TunggakanEntity>>> getTunggakan({
    required int siswaId,
    required int tarifSppId,
    required int tahun,
  }) async => success([]);

  @override
  Future<Result<StatusPembayaranEntity>> getStatusPembayaran(
    int siswaId, {
    String? tahunAjaran,
  }) async => success(const StatusPembayaranEntity());

  @override
  Future<Result<List<PembayaranSppEntity>>> bayarMultiple({
    required int siswaId,
    required int tarifSppId,
    required List<int> bulan,
    required int tahun,
    double? jumlahBayarPerBulan,
    String? tanggalBayar,
    String? metodePembayaran,
    String? keterangan,
  }) async {
    bayarMultipleCalls++;
    return success([]);
  }

  @override
  Future<Result<List<PembayaranSppEntity>>> getPembayaranList({
    String? search,
    int? tahun,
    int? bulan,
    String? status,
  }) => throw UnimplementedError();
  @override
  Future<Result<PembayaranSppEntity>> getPembayaranDetail(int id) =>
      throw UnimplementedError();
  @override
  Future<Result<LaporanPeriodeEntity>> getLaporanPeriode({
    int? tahun,
    int? bulanDari,
    int? bulanSampai,
    int? kelasId,
    int? tahunAjaranId,
  }) => throw UnimplementedError();
  @override
  Future<Result<List<TarifSppEntity>>> getTarifList({String? search}) =>
      throw UnimplementedError();
  @override
  Future<Result<TarifSppEntity>> getTarifDetail(int id) =>
      throw UnimplementedError();
  @override
  Future<Result<TarifSppEntity>> getTarifByKelas(
    int kelasId, {
    int? tahunAjaranId,
  }) => throw UnimplementedError();
  @override
  Future<Result<DendaEntity>> hitungDenda({
    required int tarifSppId,
    required int bulan,
    required int tahun,
    String? tanggalBayar,
  }) => throw UnimplementedError();
  @override
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
  }) => throw UnimplementedError();
  @override
  Future<Result<PembayaranOnlineEntity>> bayarOnline({
    required int siswaId,
    required int tarifSppId,
    required int bulan,
    required int tahun,
  }) => throw UnimplementedError();
}
