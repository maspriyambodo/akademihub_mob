import 'package:akademihub_mob/features/dashboard/data/models/dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves Go dashboard total_mapel summary', () {
    final dashboard = DashboardModel.fromJson({
      'role': 'GURU',
      'summary': {'total_mapel': 7},
    }).toEntity();

    expect(dashboard.summary?['total_mapel'], 7);
  });

  test('preserves legacy total_mata_pelajaran summary', () {
    final dashboard = DashboardModel.fromJson({
      'role': 'GURU',
      'summary': {'total_mata_pelajaran': 6},
    }).toEntity();

    expect(dashboard.summary?['total_mata_pelajaran'], 6);
  });

  test('ignores ppdb and ppdb_summary fields in admin payload without error', () {
    final json = {
      'role': 'admin',
      'summary': {
        'total_siswa': 120,
        'total_guru': 15,
        'ppdb': {'total_pendaftar': 50},
        'ppdb_summary': {'gelombang_aktif': 1},
      },
    };

    final dashboard = DashboardModel.fromJson(json).toEntity();
    expect(dashboard.role, 'admin');
    expect(dashboard.summary?['total_siswa'], 120);
  });
}
