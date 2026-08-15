import 'package:akademihub_mob/core/error/exceptions.dart';
import 'package:akademihub_mob/features/ujian/data/models/ujian_session_model.dart';
import 'package:akademihub_mob/features/ujian/domain/entities/ujian_session_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const statuses = {
    'not_started': UjianSessionStatus.belumMulai,
    'in_progress': UjianSessionStatus.mengerjakan,
    'completed': UjianSessionStatus.selesai,
    'awaiting_grading': UjianSessionStatus.menungguKoreksi,
  };

  test('status_code authoritative untuk empat status exam-engine', () {
    for (final entry in statuses.entries) {
      final session = UjianSessionModel.fromJson({
        'status': 99,
        'status_code': entry.key,
      }).toEntity();
      expect(session.status, entry.value, reason: entry.key);
    }
  });

  test('status angka 1/2/3/4 menjadi fallback tanpa status_code', () {
    final expected = statuses.values.toList();
    for (var status = 1; status <= 4; status++) {
      final session = UjianSessionModel.fromJson({'status': status}).toEntity();
      expect(session.status, expected[status - 1], reason: '$status');
    }
  });

  test('parses awaiting_grading fixture dari response struct Go', () {
    final session = UjianSessionModel.fromJson({
      'id': 44,
      'trx_ujian_id': 10,
      'ujian': {'id': 10, 'nama': 'Ulangan Pecahan'},
      'status': 4,
      'status_code': 'awaiting_grading',
      'total_benar': 10,
      'total_salah': 2,
      'nilai_akhir': null,
      'nilai_provisional': 50,
      'sisa_waktu': 0,
    }).toEntity();

    expect(session.status, UjianSessionStatus.menungguKoreksi);
    expect(session.nilaiAkhir, isNull);
    expect(session.nilaiProvisional, 50);
  });
  test('parses deadline_at and timed_out_at from Go backend struct', () {
    final session = UjianSessionModel.fromJson({
      'id': 45,
      'trx_ujian_id': 10,
      'status': 2,
      'status_code': 'in_progress',
      'deadline_at': '2026-08-16 14:00:00',
      'timed_out_at': '2026-08-16 14:00:00',
    }).toEntity();

    expect(session.deadlineAt, '2026-08-16 14:00:00');
    expect(session.timedOutAt, '2026-08-16 14:00:00');
    expect(session.isTimedOut, isTrue);
  });

  test('status tidak dikenal menghasilkan error kontrak', () {
    expect(
      () => UjianSessionModel.fromJson({
        'status': 1,
        'status_code': 'paused',
      }).toEntity(),
      throwsA(isA<ServerException>()),
    );
    expect(
      () => UjianSessionModel.fromJson({'status': 0}).toEntity(),
      throwsA(isA<ServerException>()),
    );
  });
}
