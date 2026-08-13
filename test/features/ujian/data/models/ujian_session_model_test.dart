import 'package:akademihub_mob/features/ujian/data/models/ujian_session_model.dart';
import 'package:akademihub_mob/features/ujian/domain/entities/ujian_session_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses exam-engine session status and result', () {
    final session = UjianSessionModel.fromJson({
      'id': 44,
      'trx_ujian_id': 10,
      'ujian': {'id': 10, 'nama': 'Ulangan Pecahan'},
      'status': 2,
      'total_benar': 18,
      'total_salah': 2,
      'nilai_akhir': 90,
      'sisa_waktu': 1200,
    }).toEntity();

    expect(session.id, 44);
    expect(session.namaUjian, 'Ulangan Pecahan');
    expect(session.status, UjianSessionStatus.selesai);
    expect(session.nilaiAkhir, 90);
    expect(session.sisaWaktu, 1200);
  });

  test('maps exam-engine in-progress status', () {
    final session = UjianSessionModel.fromJson({
      'id': 44,
      'trx_ujian_id': 10,
      'status': 1,
    }).toEntity();

    expect(session.status, UjianSessionStatus.mengerjakan);
  });
}
