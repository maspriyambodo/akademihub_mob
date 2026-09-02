import 'package:akademihub_mob/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:akademihub_mob/features/dashboard/presentation/widgets/guru_dashboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget(DashboardEntity data) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: GuruDashboardWidget(data: data, permissions: const []),
        ),
      ),
    );
  }

  testWidgets('renders total_mapel from Go dashboard-engine fixture', (
    tester,
  ) async {
    final data = const DashboardEntity(
      role: 'guru',
      profile: {'nama': 'Guru Test', 'nip': '123456'},
      summary: {
        'total_siswa_wali': 30,
        'total_mapel': 7,
        'total_kelas_wali': 2,
        'tugas_belum_dinilai': 5,
      },
    );

    await tester.pumpWidget(buildWidget(data));

    expect(find.text('Mata Pelajaran'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets(
    'falls back to legacy total_mata_pelajaran when total_mapel is missing',
    (tester) async {
      final data = const DashboardEntity(
        role: 'guru',
        profile: {'nama': 'Guru Test', 'nip': '123456'},
        summary: {
          'total_siswa_wali': 30,
          'total_mata_pelajaran': 6,
          'total_kelas_wali': 2,
          'tugas_belum_dinilai': 5,
        },
      );

      await tester.pumpWidget(buildWidget(data));

      expect(find.text('Mata Pelajaran'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    },
  );
}
