import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/rapor/domain/entities/rapor_detail_entity.dart';
import 'package:akademihub_mob/features/rapor/domain/entities/rapor_entity.dart';
import 'package:akademihub_mob/features/rapor/domain/repositories/rapor_repository.dart';
import 'package:akademihub_mob/features/rapor/domain/usecases/get_rapor_list_usecase.dart';
import 'package:akademihub_mob/features/rapor/domain/usecases/manage_rapor_usecases.dart';
import 'package:akademihub_mob/features/rapor/presentation/bloc/rapor_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create reloads scoped list after success', () async {
    final repo = _RaporRepository();
    final bloc = _bloc(repo);
    final loaded = bloc.stream.firstWhere((s) => s is RaporLoaded);
    bloc.add(const RaporLoadRequested(role: 'admin', canCreate: true));
    await loaded;

    final reloaded = bloc.stream.firstWhere(
      (s) => s is RaporLoaded && s.items.length == 2,
    );
    bloc.add(
      const RaporCreateRequested(
        siswaId: 4,
        semester: 2,
        sakit: 0,
        izin: 0,
        tanpaKeterangan: 0,
      ),
    );
    await reloaded;

    expect(repo.createCalls, 1);
    expect(repo.listCalls, 2);
    await bloc.close();
  });

  test('create is blocked without rapor.create', () async {
    final repo = _RaporRepository();
    final bloc = _bloc(repo);
    final failure = bloc.stream.firstWhere((s) => s is RaporActionFailure);
    bloc.add(const RaporLoadRequested(role: 'admin'));
    await bloc.stream.firstWhere((s) => s is RaporLoaded);
    bloc.add(
      const RaporCreateRequested(
        siswaId: 4,
        semester: 2,
        sakit: 0,
        izin: 0,
        tanpaKeterangan: 0,
      ),
    );
    expect(
      (await failure as RaporActionFailure).message,
      contains('tidak memiliki izin'),
    );
    expect(repo.createCalls, 0);
    await bloc.close();
  });
}

RaporBloc _bloc(_RaporRepository repo) => RaporBloc(
  getRaporList: GetRaporListUseCase(repo),
  getRaporBySiswa: GetRaporBySiswaUseCase(repo),
  createRapor: CreateRaporUseCase(repo),
  updateRapor: UpdateRaporUseCase(repo),
  deleteRapor: DeleteRaporUseCase(repo),
);

class _RaporRepository implements RaporRepository {
  int createCalls = 0;
  int listCalls = 0;
  final _items = <RaporEntity>[
    const RaporEntity(id: 1, siswaId: 3, semesterKode: '1'),
  ];

  @override
  Future<Result<RaporEntity>> createRapor({
    required int siswaId,
    required int semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
    List<Map<String, dynamic>>? details,
  }) async {
    createCalls++;
    _items.add(RaporEntity(id: 2, siswaId: siswaId, semesterKode: '$semester'));
    return success(_items.last);
  }

  @override
  Future<Result<List<RaporEntity>>> getRaporList({String? search}) async {
    listCalls++;
    return success(List.of(_items));
  }

  @override
  Future<Result<List<RaporEntity>>> getRaporBySiswa(int siswaId) async =>
      success(List.of(_items));

  @override
  Future<Result<bool>> deleteRapor(int id) async => success(true);

  @override
  Future<Result<RaporEntity>> updateRapor({
    required int id,
    int? siswaId,
    int? semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
  }) async => success(_items.first);

  @override
  Future<Result<RaporDetailEntity>> getRaporDetail(int raporId) =>
      throw UnimplementedError();

  @override
  Future<Result<String>> exportRaporSiswa(int siswaId) =>
      throw UnimplementedError();
}
