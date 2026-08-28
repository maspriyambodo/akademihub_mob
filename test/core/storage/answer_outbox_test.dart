import 'dart:io';

import 'package:akademihub_mob/core/storage/answer_outbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late AnswerOutbox outbox;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('answer_outbox_test');
    Hive.init(directory.path);
    box = await Hive.openBox<dynamic>(
      'test-${DateTime.now().microsecondsSinceEpoch}',
    );
    outbox = AnswerOutbox(box);
    await outbox.bindSession(userId: 1, tenantUuid: 'tenant-a');
  });

  tearDown(() async {
    await box.close();
    await directory.delete(recursive: true);
  });

  test(
    'coalesces latest answer and protects newer operation from old ack',
    () async {
      final first = await outbox.enqueue(
        module: 'cbt',
        sessionId: 7,
        questionId: 11,
        payload: const {'mst_soal_opsi_id': 1},
      );
      final latest = await outbox.enqueue(
        module: 'cbt',
        sessionId: 7,
        questionId: 11,
        payload: const {'mst_soal_opsi_id': 2},
      );

      await outbox.acknowledge(first);

      final pending = outbox.pending('cbt', 7);
      expect(pending, hasLength(1));
      expect(pending.single.id, latest.id);
      expect(pending.single.payload, latest.payload);
    },
  );

  test(
    'persists distinct questions in sequence and clears one session',
    () async {
      await outbox.enqueue(
        module: 'tmb',
        sessionId: 9,
        questionId: 2,
        payload: const {'opsi_id': 20},
      );
      await outbox.enqueue(
        module: 'tmb',
        sessionId: 9,
        questionId: 3,
        payload: const {'opsi_id': 30},
      );

      expect(outbox.pending('tmb', 9).map((e) => e.questionId), [2, 3]);

      await outbox.clearSession('tmb', 9);
      expect(outbox.pending('tmb', 9), isEmpty);
    },
  );

  test('survives recreation with retry metadata', () async {
    final operation = await outbox.enqueue(
      module: 'cbt',
      sessionId: 7,
      questionId: 11,
      payload: const {'mst_soal_opsi_id': 1},
    );
    await outbox.recordRetry(operation);

    final restored = AnswerOutbox(box);
    await restored.bindSession(userId: 1, tenantUuid: 'tenant-a');
    final pending = restored.pending('cbt', 7);

    expect(pending, hasLength(1));
    expect(pending.single.id, operation.id);
    expect(pending.single.retryCount, 1);
    expect(pending.single.createdAt.isUtc, isTrue);
  });

  test('removes drafts from another user or tenant session', () async {
    await outbox.enqueue(
      module: 'tmb',
      sessionId: 9,
      questionId: 2,
      payload: const {'opsi_id': 20},
    );

    await outbox.bindSession(userId: 2, tenantUuid: 'tenant-b');

    expect(outbox.pending('tmb', 9), isEmpty);
    expect(box.values, isEmpty);
  });
}
