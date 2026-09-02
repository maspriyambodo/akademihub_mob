import 'package:akademihub_mob/core/theme/app_theme.dart';
import 'package:akademihub_mob/core/widgets/app_metric_tile.dart';
import 'package:akademihub_mob/core/widgets/app_section_header.dart';
import 'package:akademihub_mob/core/widgets/app_status_badge.dart';
import 'package:akademihub_mob/core/widgets/app_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSurfaceCard', () {
    testWidgets('renders content, handles tap, and applies semantics', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppSurfaceCard(
              semanticLabel: 'Kartu Utama',
              onTap: () => tapped = true,
              accentColor: AppColors.primary,
              child: const Text('Konten Card'),
            ),
          ),
        ),
      );

      expect(find.text('Konten Card'), findsOneWidget);
      await tester.tap(find.text('Konten Card'));
      expect(tapped, isTrue);

      final semantics = tester.getSemantics(find.byType(AppSurfaceCard));
      expect(semantics.label, contains('Kartu Utama'));
    });

    testWidgets('renders safely without tap or accentColor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AppSurfaceCard(child: Text('Plain Card'))),
        ),
      );

      expect(find.text('Plain Card'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppStatusBadge', () {
    testWidgets('renders badge text and icon with correct tone colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppStatusBadge(
              label: 'Hadir',
              tone: AppStatusTone.success,
              icon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      expect(find.text('Hadir'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(AppStatusBadge));
      expect(semantics.label, 'Hadir, status');
    });
  });

  group('AppSectionHeader', () {
    testWidgets('renders title, eyebrow, and executes action', (tester) async {
      var actionTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Jadwal Hari Ini',
              eyebrow: 'Akademik',
              actionLabel: 'Lihat Semua',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('AKADEMIK'), findsOneWidget);
      expect(find.text('Jadwal Hari Ini'), findsOneWidget);
      expect(find.text('Lihat Semua'), findsOneWidget);

      await tester.tap(find.text('Lihat Semua'));
      expect(actionTriggered, isTrue);

      // Verify minimum touch target >= 48dp
      final buttonSize = tester.getSize(find.byType(TextButton));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
    });
  });

  group('AppMetricTile', () {
    testWidgets('renders metric data and semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppMetricTile(
              label: 'Kehadiran',
              value: '95%',
              icon: Icons.person_outline,
              tone: AppStatusTone.info,
              supportingText: 'Bulan ini',
            ),
          ),
        ),
      );

      expect(find.text('Kehadiran'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('Bulan ini'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(AppMetricTile));
      expect(semantics.label, 'Kehadiran, 95%, Bulan ini');
    });

    testWidgets('handles high text scale factor safely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SizedBox(
                width: 160,
                child: AppMetricTile(
                  label: 'Presensi Sangat Panjang',
                  value: '100%',
                  icon: Icons.school_outlined,
                  tone: AppStatusTone.success,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Presensi Sangat Panjang'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
