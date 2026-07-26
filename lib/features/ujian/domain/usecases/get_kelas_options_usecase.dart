import '../../../../core/error/result.dart';
import '../entities/kelas_option_entity.dart';
import '../repositories/ujian_repository.dart';

class GetKelasOptionsUseCase {
  final UjianRepository _repository;
  const GetKelasOptionsUseCase(this._repository);

  Future<Result<List<KelasOptionEntity>>> call({int? waliGuruId}) =>
      _repository.getKelasOptions(waliGuruId: waliGuruId);
}
