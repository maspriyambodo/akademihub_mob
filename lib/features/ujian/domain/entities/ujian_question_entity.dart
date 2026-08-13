import 'package:equatable/equatable.dart';

class UjianOptionEntity extends Equatable {
  final int id;
  final String text;

  const UjianOptionEntity({required this.id, required this.text});

  @override
  List<Object> get props => [id, text];
}

class UjianAnswerEntity extends Equatable {
  final int id;
  final int? optionId;
  final String? text;
  final bool doubtful;

  const UjianAnswerEntity({
    required this.id,
    this.optionId,
    this.text,
    this.doubtful = false,
  });

  bool get isAnswered => optionId != null || (text?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [id, optionId, text, doubtful];
}

class UjianQuestionEntity extends Equatable {
  final int id;
  final String question;
  final int type;
  final String? mediaPath;
  final List<UjianOptionEntity> options;
  final UjianAnswerEntity? answer;

  const UjianQuestionEntity({
    required this.id,
    required this.question,
    required this.type,
    this.mediaPath,
    this.options = const [],
    this.answer,
  });

  bool get isMultipleChoice => type == 1;
  bool get isEssay => type == 2;
  bool get isAnswered => answer?.isAnswered ?? false;

  UjianQuestionEntity copyWith({UjianAnswerEntity? answer}) =>
      UjianQuestionEntity(
        id: id,
        question: question,
        type: type,
        mediaPath: mediaPath,
        options: options,
        answer: answer ?? this.answer,
      );

  @override
  List<Object?> get props => [id, question, type, mediaPath, options, answer];
}
