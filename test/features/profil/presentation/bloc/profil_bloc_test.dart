import 'package:akademihub_mob/core/error/failures.dart';
import 'package:akademihub_mob/core/error/result.dart' as app_result;
import 'package:akademihub_mob/features/profil/domain/entities/app_info_entity.dart';
import 'package:akademihub_mob/features/profil/domain/entities/perangkat_entity.dart';
import 'package:akademihub_mob/features/profil/domain/entities/sekolah_entity.dart';
import 'package:akademihub_mob/features/profil/domain/repositories/profil_repository.dart';
import 'package:akademihub_mob/features/profil/domain/usecases/get_app_info_usecase.dart';
import 'package:akademihub_mob/features/profil/domain/usecases/get_perangkat_usecase.dart';
import 'package:akademihub_mob/features/profil/domain/usecases/get_sekolah_usecase.dart';
import 'package:akademihub_mob/features/profil/presentation/bloc/profil_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfilRepository implements ProfilRepository {
  @override
  Future<app_result.Result<SekolahEntity>> getSekolahAktif({
    int? id,
    String? uuid,
    String? nama,
  }) async => app_result.fail(const ForbiddenFailure('Tidak memiliki izin sekolah.view'));

  @override
  Future<app_result.Result<List<PerangkatEntity>>> getPerangkatUser(int userId) async =>
      app_result.success(const []);

  @override
  Future<app_result.Result<AppInfoEntity>> getAppInfo() async => app_result.success(
    const AppInfoEntity(
      namaAplikasi: 'AkademiHub',
      versi: '1.0.0',
      buildNumber: '1',
      packageName: 'id.akademihub.mob',
    ),
  );
}

void main() {
  test(
    'ProfilBloc memakai fallbackSekolah saat tidak ada izin sekolah.view',
    () async {
      final repo = _FakeProfilRepository();
      final bloc = ProfilBloc(
        getSekolahAktif: GetSekolahAktifUseCase(repo),
        getPerangkatUser: GetPerangkatUserUseCase(repo),
        getAppInfo: GetAppInfoUseCase(repo),
      );
      addTearDown(bloc.close);

      const fallback = SekolahEntity(
        namaSekolah: 'SMA Negeri 1 Example',
        uuid: 'c110179a-9b7b-4e4c-9fb6-e283d2924872',
      );

      bloc.add(
        const ProfilLoadRequested(
          userId: 10,
          bisaLihatSekolah: false,
          fallbackSekolah: fallback,
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProfilLoading>(),
          isA<ProfilLoaded>()
              .having((s) => s.sekolah?.namaSekolah, 'namaSekolah', 'SMA Negeri 1 Example')
              .having((s) => s.sekolahDariCache, 'sekolahDariCache', isTrue)
              .having((s) => s.sekolahError, 'sekolahError', isNull),
        ]),
      );
    },
  );
}
