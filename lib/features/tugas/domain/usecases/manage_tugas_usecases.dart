import '../../../../core/error/result.dart';
import '../entities/tugas_entity.dart';
import '../repositories/tugas_repository.dart';

class CreateTugasUseCase {
  final TugasRepository _repository;
  const CreateTugasUseCase(this._repository);

  Future<Result<TugasEntity>> call({
    required int guruMapelId,
    required int kelasId,
    required String judul,
    required String tenggatWaktu,
    String? deskripsi,
    String? fileLampiran,
    int? status,
  }) => _repository.createTugas(
    guruMapelId: guruMapelId,
    kelasId: kelasId,
    judul: judul,
    tenggatWaktu: tenggatWaktu,
    deskripsi: deskripsi,
    fileLampiran: fileLampiran,
    status: status,
  );
}

class UpdateTugasUseCase {
  final TugasRepository _repository;
  const UpdateTugasUseCase(this._repository);

  Future<Result<TugasEntity>> call({
    required int id,
    int? guruMapelId,
    int? kelasId,
    String? judul,
    String? deskripsi,
    String? fileLampiran,
    String? tenggatWaktu,
    int? status,
  }) => _repository.updateTugas(
    id: id,
    guruMapelId: guruMapelId,
    kelasId: kelasId,
    judul: judul,
    deskripsi: deskripsi,
    fileLampiran: fileLampiran,
    tenggatWaktu: tenggatWaktu,
    status: status,
  );
}

class DeleteTugasUseCase {
  final TugasRepository _repository;
  const DeleteTugasUseCase(this._repository);

  Future<Result<bool>> call(int id) => _repository.deleteTugas(id);
}
