import 'package:akademihub_mob/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:akademihub_mob/features/dashboard/presentation/widgets/siswa_dashboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(DashboardEntity data) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SiswaDashboardWidget(data: data, permissions: const []),
        ),
      ),
    );
  }

  testWidgets('renders nama_mapel and nama_ujian from recent_grades', (
    tester,
  ) async {
    const data = DashboardEntity(
      role: 'siswa',
      profile: {'nama': 'Sania Fitri'},
      recentGrades: [
        {
          'id': 1,
          'nilai': 85,
          'nama_mapel': 'Matematika',
          'nama_ujian': 'Ulangan Harian 1',
        },
      ],
    );

    await tester.pumpWidget(buildWidget(data));

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Ulangan Harian 1'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
  });
}
