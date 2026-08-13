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
}
