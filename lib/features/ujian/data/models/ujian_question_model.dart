import '../../domain/entities/ujian_question_entity.dart';

class UjianQuestionModel {
  final UjianQuestionEntity entity;

  const UjianQuestionModel(this.entity);

  factory UjianQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawAnswer = json['jawaban'];
    final answer = rawAnswer is Map
        ? UjianAnswerEntity(
            id: (rawAnswer['id'] as num?)?.toInt() ?? 0,
            optionId: (rawAnswer['mst_soal_opsi_id'] as num?)?.toInt(),
            text: rawAnswer['jawaban_teks']?.toString(),
            doubtful:
                rawAnswer['ragu_ragu'] == true ||
                (rawAnswer['ragu_ragu'] as num?)?.toInt() == 1,
          )
        : null;
    final options = (json['opsi'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (option) => UjianOptionEntity(
            id: (option['id'] as num?)?.toInt() ?? 0,
            text: option['teks_opsi']?.toString() ?? '',
          ),
        )
        .toList();
    return UjianQuestionModel(
      UjianQuestionEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        question: json['pertanyaan']?.toString() ?? '',
        type: (json['tipe'] as num?)?.toInt() ?? 0,
        mediaPath: json['media_path']?.toString(),
        options: options,
        answer: answer,
      ),
    );
  }

  UjianQuestionEntity toEntity() => entity;
}
