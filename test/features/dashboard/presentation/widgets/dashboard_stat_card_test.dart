import 'package:akademihub_mob/core/theme/app_theme.dart';
import 'package:akademihub_mob/features/dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in <String, ThemeData>{
    'default Material theme': ThemeData(),
    'production theme': AppTheme.lightTheme,
  }.entries) {
    testWidgets('renders safely with ${entry.key}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: entry.value,
          home: const Scaffold(
            body: DashboardStatCard(
              title: 'Mata Pelajaran',
              value: '7',
              icon: Icons.book_outlined,
              color: Colors.indigo,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Mata Pelajaran'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });
  }
}
