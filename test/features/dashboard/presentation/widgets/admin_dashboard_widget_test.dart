import 'package:akademihub_mob/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:akademihub_mob/features/dashboard/presentation/widgets/admin_dashboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin dashboard ignores PPDB fields in fixture payload', (tester) async {
    final data = const DashboardEntity(
      role: 'admin',
      profile: {'nama': 'Admin Test'},
      summaryCards: {
        'total_siswa_aktif': 120,
        'total_guru': 15,
        'total_kelas': 10,
        'ppdb': {'total_pendaftar': 50},
        'ppdb_summary': {'gelombang_aktif': 1},
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminDashboardWidget(
              data: data,
              permissions: const [],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Total Siswa Aktif'), findsOneWidget);
    expect(find.text('Total Guru'), findsOneWidget);
    expect(find.textContaining('PPDB', findRichText: true), findsNothing);
    expect(find.textContaining('ppdb', findRichText: true), findsNothing);
  });
}
