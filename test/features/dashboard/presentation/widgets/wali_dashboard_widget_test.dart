import 'package:akademihub_mob/core/theme/app_theme.dart';
import 'package:akademihub_mob/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:akademihub_mob/features/dashboard/presentation/widgets/wali_dashboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders wali dashboard with children details and SPP status', (
    tester,
  ) async {
    const data = DashboardEntity(
      role: 'wali',
      children: [
        {
          'nama': 'Ahmad Fauzi',
          'kelas': 'X RPL 1',
          'absensi_hari_ini': 'Hadir',
          'tunggakan_spp_count': 0,
        },
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: WaliDashboardWidget(
              data: data,
              permissions: ['absensi.view', 'keuangan.view'],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Status Anak Asuhan'), findsOneWidget);
    expect(find.text('Ahmad Fauzi'), findsOneWidget);
    expect(find.text('Kelas: X RPL 1'), findsOneWidget);
    expect(find.text('Hadir'), findsOneWidget);
    expect(find.text('Lunas'), findsOneWidget);
  });
}
