import 'dart:async';

import 'package:akademihub_mob/core/error/failures.dart';
import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/ujian/domain/entities/ujian_question_entity.dart';
import 'package:akademihub_mob/features/ujian/domain/entities/ujian_session_entity.dart';
import 'package:akademihub_mob/features/ujian/domain/repositories/ujian_repository.dart';
import 'package:akademihub_mob/features/ujian/presentation/pages/ujian_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    repository.currentSession = repository.session.copyWith(
      status: UjianSessionStatus.menungguKoreksi,
      nilaiProvisional: 50,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: UjianSessionPage(
          repository: repository,
          session: repository.currentSession,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('awaiting-grading')), findsOneWidget);
    expect(find.byKey(const Key('provisional-result')), findsOneWidget);
    expect(find.text('Nilai sementara 50.00'), findsOneWidget);
    expect(find.text('Dua tambah dua?'), findsNothing);
    expect(repository.questionFetches, 0);
  });

  testWidgets(
    'refresh transitions awaiting grading to completed final result',
    (tester) async {
      final repository = _FakeRepository();
      repository.currentSession = repository.session.copyWith(
        status: UjianSessionStatus.menungguKoreksi,
        nilaiProvisional: 50,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: UjianSessionPage(
            repository: repository,
            session: repository.currentSession,
          ),
        ),
      );
      await tester.pumpAndSettle();

      repository.currentSession = repository.session.copyWith(
        status: UjianSessionStatus.selesai,
        nilaiAkhir: 95.5,
      );

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(repository.sessionFetches, 1);
      expect(find.byKey(const Key('exam-result')), findsOneWidget);
      expect(find.text('Nilai 95.50'), findsOneWidget);
    },
  );
  testWidgets('timed_out_at displays banner and disables inputs', (
    tester,
  ) async {
    final repository = _FakeRepository();
    repository.currentSession = repository.session.copyWith(
      status: UjianSessionStatus.mengerjakan,
      timedOutAt: '2026-08-16 12:00:00',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: UjianSessionPage(
          repository: repository,
          session: repository.currentSession,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeout-banner')), findsOneWidget);
    expect(find.text('Waktu Ujian Habis'), findsOneWidget);
    expect(repository.questionFetches, 0);
  });

  testWidgets('deadline reached disables inputs and refreshes session', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final deadline = DateTime.utc(2026, 8, 16, 12, 0, 0);
    var simulatedTime = DateTime.utc(2026, 8, 16, 11, 59, 59);

    repository.currentSession = repository.session.copyWith(
      status: UjianSessionStatus.mengerjakan,
      deadlineAt: deadline.toIso8601String(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UjianSessionPage(
          repository: repository,
          session: repository.currentSession,
          nowProvider: () => simulatedTime,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sisa waktu: 00:01'), findsOneWidget);
    expect(repository.questionFetches, 1);

    // Advance time past deadline
    simulatedTime = DateTime.utc(2026, 8, 16, 12, 0, 1);
    repository.currentSession = repository.session.copyWith(
      status: UjianSessionStatus.selesai,
      timedOutAt: deadline.toIso8601String(),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(repository.sessionFetches, 1);
    expect(find.byKey(const Key('timeout-banner')), findsOneWidget);
  });

  testWidgets('save failure refreshes session on deadline error', (
    tester,
  ) async {
    final repository = _DeadlineErrorRepository();
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

    expect(find.text('Deadline reached on server'), findsOneWidget);
    expect(repository.sessionFetches, 1);
  });

  testWidgets('records one violation while the prior report is pending', (
    tester,
  ) async {
    const kioskChannel = MethodChannel('com.akademihub.app/kiosk');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kioskChannel, (call) async => true);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(kioskChannel, null),
    );
    final repository = _PendingViolationRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: UjianSessionPage(
          repository: repository,
          session: repository.session,
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    // A second valid background cycle must not create concurrent telemetry.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    expect(repository.violationReports, 1);
    repository.completeViolation();
    await tester.pumpAndSettle();
  });

  testWidgets('closes kiosk when backend reports the violation threshold', (
    tester,
  ) async {
    const kioskChannel = MethodChannel('com.akademihub.app/kiosk');
    var stopKioskCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kioskChannel, (call) async {
          if (call.method == 'stopKioskMode') stopKioskCalls++;
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(kioskChannel, null),
    );
    final repository = _ThresholdViolationRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: UjianSessionPage(
          repository: repository,
          session: repository.session,
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump();

    expect(repository.violationReports, 1);
    expect(stopKioskCalls, 1);
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
  late UjianSessionEntity currentSession = session;
  int questionFetches = 0;
  int sessionFetches = 0;
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
  Future<Result<UjianSessionEntity>> getSesi(int sesiId) async {
    sessionFetches++;
    return success(currentSession);
  }

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

class _DeadlineErrorRepository extends _FakeRepository {
  @override
  Future<Result<UjianAnswerEntity>> saveJawaban({
    required int sesiId,
    required int soalId,
    int? opsiId,
    String? teks,
    required bool raguRagu,
  }) async {
    return const ResultFailure(ServerFailure('Deadline reached on server'));
  }
}

class _PendingViolationRepository extends _FakeRepository {
  final _violation = Completer<Result<Map<String, dynamic>>>();
  int violationReports = 0;

  @override
  Future<Result<Map<String, dynamic>>> reportViolation({
    required int sesiId,
    required String type,
  }) {
    violationReports++;
    return _violation.future;
  }

  void completeViolation() => _violation.complete(success(const {}));
}

class _ThresholdViolationRepository extends _FakeRepository {
  int violationReports = 0;

  @override
  Future<Result<Map<String, dynamic>>> reportViolation({
    required int sesiId,
    required String type,
  }) async {
    violationReports++;
    return success(const {'violation_count': 3, 'auto_submitted': false});
  }
}
