import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AnswerOperation {
  final String id;
  final String module;
  final int sessionId;
  final int questionId;
  final int sequence;
  final Map<String, dynamic> payload;

  const AnswerOperation({
    required this.id,
    required this.module,
    required this.sessionId,
    required this.questionId,
    required this.sequence,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'module': module,
    'session_id': sessionId,
    'question_id': questionId,
    'sequence': sequence,
    'payload': payload,
  };

  factory AnswerOperation.fromJson(Map<dynamic, dynamic> json) =>
      AnswerOperation(
        id: json['id'] as String,
        module: json['module'] as String,
        sessionId: (json['session_id'] as num).toInt(),
        questionId: (json['question_id'] as num).toInt(),
        sequence: (json['sequence'] as num).toInt(),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
      );
}

class AnswerOutbox {
  static const boxName = 'answer_outbox_v1';
  static const _keyName = 'answer_outbox_key_v1';

  final Box<dynamic> _box;
  int _sequence = DateTime.now().microsecondsSinceEpoch;

  AnswerOutbox(this._box);

  static Future<AnswerOutbox> open(FlutterSecureStorage storage) async {
    await Hive.initFlutter();
    var encodedKey = await storage.read(key: _keyName);
    if (encodedKey == null) {
      final random = Random.secure();
      encodedKey = base64UrlEncode(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      await storage.write(key: _keyName, value: encodedKey);
    }
    final box = await Hive.openBox<dynamic>(
      boxName,
      encryptionCipher: HiveAesCipher(base64Url.decode(encodedKey)),
    );
    return AnswerOutbox(box);
  }

  Future<AnswerOperation> enqueue({
    required String module,
    required int sessionId,
    required int questionId,
    required Map<String, dynamic> payload,
  }) async {
    final sequence = ++_sequence;
    final operation = AnswerOperation(
      id: '$sequence-${Random.secure().nextInt(1 << 32)}',
      module: module,
      sessionId: sessionId,
      questionId: questionId,
      sequence: sequence,
      payload: payload,
    );
    await _box.put(_key(module, sessionId, questionId), operation.toJson());
    return operation;
  }

  List<AnswerOperation> pending(String module, int sessionId) {
    final operations = <AnswerOperation>[];
    for (final value in _box.values) {
      try {
        final operation = AnswerOperation.fromJson(value as Map);
        if (operation.module == module && operation.sessionId == sessionId) {
          operations.add(operation);
        }
      } on Object {
        // Ignore malformed legacy records; they are never sent.
      }
    }
    operations.sort((a, b) => a.sequence.compareTo(b.sequence));
    return operations;
  }

  Future<void> acknowledge(AnswerOperation operation) async {
    final key = _key(
      operation.module,
      operation.sessionId,
      operation.questionId,
    );
    final current = _box.get(key);
    if (current is Map && current['id'] == operation.id) await _box.delete(key);
  }

  Future<void> clearSession(String module, int sessionId) async {
    for (final operation in pending(module, sessionId)) {
      await _box.delete(_key(module, sessionId, operation.questionId));
    }
  }

  Future<void> clear() => _box.clear();

  String _key(String module, int sessionId, int questionId) =>
      '$module:$sessionId:$questionId';
}
