import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/ujian/domain/entities/ujian_question_entity.dart';
import 'package:akademihub_mob/features/ujian/domain/entities/ujian_session_entity.dart';
import 'package:akademihub_mob/features/ujian/domain/repositories/ujian_repository.dart';
import 'package:akademihub_mob/features/ujian/presentation/pages/ujian_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saves PG answer and blocks finalize while another is empty', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: UjianSessionPage(
          repository: repository,
          session: repository.session,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empat'));
    await tester.pumpAndSettle();
    expect(repository.saved, [(11, 102, null, false)]);
    expect(find.text('Tersimpan'), findsOneWidget);

    final finalize = find.byKey(const Key('finalize-exam'));
    await tester.scrollUntilVisible(
      finalize,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finalize);
    await tester.pump();
    expect(find.text('1 soal belum dijawab'), findsOneWidget);
    expect(repository.finalized, isFalse);
  });

  testWidgets('completed session shows result without fetching questions', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: UjianSessionPage(
          repository: repository,
          session: repository.session.copyWith(
            status: UjianSessionStatus.selesai,
            nilaiAkhir: 80,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exam-result')), findsOneWidget);
    expect(repository.questionFetches, 0);
    expect(find.text('Dua tambah dua?'), findsNothing);
    expect(find.text('Mulai Ujian'), findsNothing);
    expect(find.byKey(const Key('finalize-exam')), findsNothing);
  });

  testWidgets(
    'not-started session only offers start without fetching questions',
    (tester) async {
      final repository = _FakeRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: UjianSessionPage(
            repository: repository,
            session: repository.session.copyWith(
              status: UjianSessionStatus.belumMulai,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mulai Ujian'), findsOneWidget);
      expect(find.byKey(const Key('finalize-exam')), findsNothing);
      expect(repository.questionFetches, 0);
    },
  );

  testWidgets('awaiting grading is read-only without final score', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: UjianSessionPage(
          repository: repository,
          session: repository.session.copyWith(
            status: UjianSessionStatus.menungguKoreksi,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('awaiting-grading')), findsOneWidget);
    expect(find.text('Mulai Ujian'), findsNothing);
    expect(find.byKey(const Key('finalize-exam')), findsNothing);
    expect(find.byKey(const Key('exam-result')), findsNothing);
    expect(repository.questionFetches, 0);
  });
}

class _FakeRepository implements UjianRepository {
  final session = const UjianSessionEntity(
    id: 7,
    ujianId: 3,
    namaUjian: 'Ulangan',
    status: UjianSessionStatus.mengerjakan,
    sisaWaktu: 600,
  );
  final saved = <(int, int?, String?, bool)>[];
  int questionFetches = 0;
  bool finalized = false;

  @override
  Future<Result<List<UjianQuestionEntity>>> getSoal(int sesiId) async {
    questionFetches++;
    return success(const [
      UjianQuestionEntity(
        id: 11,
        question: 'Dua tambah dua?',
        type: 1,
        options: [
          UjianOptionEntity(id: 101, text: 'Tiga'),
          UjianOptionEntity(id: 102, text: 'Empat'),
        ],
      ),
      UjianQuestionEntity(id: 12, question: 'Jelaskan jawabanmu', type: 2),
    ]);
  }

  @override
  Future<Result<UjianAnswerEntity>> saveJawaban({
    required int sesiId,
    required int soalId,
    int? opsiId,
    String? teks,
    required bool raguRagu,
  }) async {
    saved.add((soalId, opsiId, teks, raguRagu));
    return success(
      UjianAnswerEntity(
        id: 90,
        optionId: opsiId,
        text: teks,
        doubtful: raguRagu,
      ),
    );
  }

  @override
  Future<Result<UjianSessionEntity>> getSesi(int sesiId) async =>
      success(session);

  @override
  Future<Result<UjianSessionEntity>> selesaikanSesi(int sesiId) async {
    finalized = true;
    return success(
      session.copyWith(status: UjianSessionStatus.selesai, nilaiAkhir: 100),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
