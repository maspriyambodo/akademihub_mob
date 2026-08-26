import 'package:akademihub_mob/features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hides actions without their route permission', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardQuickActions(
            role: 'admin',
            permissions: ['materi.view'],
          ),
        ),
      ),
    );

    expect(find.text('Materi'), findsOneWidget);
    expect(find.text('Kalender'), findsNothing);
    expect(find.text('BK'), findsNothing);
    expect(find.text('EWS'), findsNothing);
  });
}
