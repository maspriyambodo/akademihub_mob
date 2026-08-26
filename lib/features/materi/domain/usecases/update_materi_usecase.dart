import '../../../../core/error/result.dart';
import '../entities/materi_entity.dart';
import '../repositories/materi_repository.dart';

class UpdateMateriUseCase {
  final MateriRepository _repository;
  const UpdateMateriUseCase(this._repository);

  Future<Result<MateriEntity>> call({
    required int id,
    int? guruMapelId,
    String? judul,
    String? deskripsi,
    String? fileMateri,
    String? linkVideo,
    int? status,
  }) => _repository.updateMateri(
    id: id,
    guruMapelId: guruMapelId,
    judul: judul,
    deskripsi: deskripsi,
    fileMateri: fileMateri,
    linkVideo: linkVideo,
    status: status,
  );
}
