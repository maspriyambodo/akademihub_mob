import 'package:akademihub_mob/features/ujian/data/models/ujian_question_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Go session question, options, and saved answer', () {
    final question = UjianQuestionModel.fromJson({
      'id': 8,
      'pertanyaan': 'Hasil 2 + 2?',
      'tipe': 1,
      'media_path': null,
      'opsi': [
        {'id': 31, 'teks_opsi': '3', 'urutan': 1},
        {'id': 32, 'teks_opsi': '4', 'urutan': 2},
      ],
      'jawaban': {
        'id': 90,
        'mst_soal_opsi_id': 32,
        'jawaban_teks': null,
        'ragu_ragu': 1,
      },
    }).toEntity();

    expect(question.isMultipleChoice, isTrue);
    expect(question.options.map((option) => option.text), ['3', '4']);
    expect(question.answer?.optionId, 32);
    expect(question.answer?.doubtful, isTrue);
    expect(question.isAnswered, isTrue);
  });

  test('parses essay saved answer', () {
    final question = UjianQuestionModel.fromJson({
      'id': 9,
      'pertanyaan': 'Jelaskan fotosintesis',
      'tipe': 2,
      'opsi': [],
      'jawaban': {
        'id': 91,
        'jawaban_teks': 'Proses tumbuhan membuat makanan',
        'ragu_ragu': 0,
      },
    }).toEntity();

    expect(question.isEssay, isTrue);
    expect(question.answer?.text, 'Proses tumbuhan membuat makanan');
  });
}
