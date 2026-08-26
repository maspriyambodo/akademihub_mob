import '../../../../core/error/result.dart';
import '../entities/materi_entity.dart';
import '../repositories/materi_repository.dart';

class CreateMateriUseCase {
  final MateriRepository _repository;
  const CreateMateriUseCase(this._repository);

  Future<Result<MateriEntity>> call({
    required int guruMapelId,
    required String judul,
    String? deskripsi,
    String? fileMateri,
    String? linkVideo,
    int? status,
  }) => _repository.createMateri(
    guruMapelId: guruMapelId,
    judul: judul,
    deskripsi: deskripsi,
    fileMateri: fileMateri,
    linkVideo: linkVideo,
    status: status,
  );
}
