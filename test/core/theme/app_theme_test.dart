import 'dart:math' as math;

import 'package:akademihub_mob/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _relativeLuminance(Color color) {
  final argb = color.toARGB32();
  int channel(int shift) => (argb >> shift) & 0xFF;
  double f(int value) {
    final c = value / 255.0;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * f(channel(16)) +
      0.7152 * f(channel(8)) +
      0.0722 * f(channel(0));
}

double contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('token inti dan theme terpasang', () {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;

    expect(AppColors.ink, const Color(0xFF102A43));
    expect(AppColors.inkSoft, const Color(0xFF334E68));
    expect(AppColors.inkMuted, const Color(0xFF526D82));
    expect(AppColors.paper, const Color(0xFFF7F5EF));
    expect(AppColors.paperBright, const Color(0xFFFFFDF8));
    expect(AppColors.paperMuted, const Color(0xFFEDF3F2));
    expect(AppColors.line, const Color(0xFFD8E2E1));
    expect(AppColors.primary, const Color(0xFF087F75));
    expect(AppColors.primaryDark, const Color(0xFF123B46));
    expect(AppColors.primaryLight, const Color(0xFFBFE8DF));
    expect(AppColors.secondary, const Color(0xFFE9A23B));
    expect(AppColors.accent, const Color(0xFF3F67B1));
    expect(AppSpacing.md, 16);
    expect(AppRadius.lg, 20);
    expect(AppTheme.lightTheme.useMaterial3, isTrue);
    expect(light.scaffoldBackgroundColor, AppColors.paper);
    expect(light.cardTheme.color, AppColors.paperBright);
    expect(light.inputDecorationTheme.fillColor, AppColors.paperBright);
    expect(
      light.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.primaryDark,
    );
    expect(light.appBarTheme.foregroundColor, AppColors.ink);
    expect(dark.useMaterial3, isTrue);
  });

  test('role dan semantic mapping lengkap', () {
    expect(
      AppColors.role('siswa'),
      const AppRoleColorGroup(
        accent: AppColors.siswaAccent,
        container: AppColors.siswaContainer,
        onContainer: AppColors.siswaOnContainer,
      ),
    );
    expect(
      AppColors.role('guru'),
      const AppRoleColorGroup(
        accent: AppColors.guruAccent,
        container: AppColors.guruContainer,
        onContainer: AppColors.guruOnContainer,
      ),
    );
    expect(
      AppColors.role('wali'),
      const AppRoleColorGroup(
        accent: AppColors.waliAccent,
        container: AppColors.waliContainer,
        onContainer: AppColors.waliOnContainer,
      ),
    );
    expect(
      AppColors.role('admin'),
      const AppRoleColorGroup(
        accent: AppColors.adminAccent,
        container: AppColors.adminContainer,
        onContainer: AppColors.adminOnContainer,
      ),
    );
    expect(
      AppColors.role('lainnya'),
      const AppRoleColorGroup(
        accent: AppColors.primary,
        container: AppColors.primaryLight,
        onContainer: AppColors.primaryDark,
      ),
    );

    expect(
      AppColors.semantic(AppStatusTone.success),
      const AppSemanticColorGroup(
        accent: AppColors.success,
        container: AppColors.successContainer,
        onContainer: AppColors.successOnContainer,
      ),
    );
    expect(
      AppColors.semantic(AppStatusTone.warning),
      const AppSemanticColorGroup(
        accent: AppColors.warning,
        container: AppColors.warningContainer,
        onContainer: AppColors.warningOnContainer,
      ),
    );
    expect(
      AppColors.semantic(AppStatusTone.error),
      const AppSemanticColorGroup(
        accent: AppColors.error,
        container: AppColors.errorContainer,
        onContainer: AppColors.errorOnContainer,
      ),
    );
    expect(
      AppColors.semantic(AppStatusTone.info),
      const AppSemanticColorGroup(
        accent: AppColors.info,
        container: AppColors.infoContainer,
        onContainer: AppColors.infoOnContainer,
      ),
    );
    expect(
      AppColors.semantic(AppStatusTone.neutral),
      const AppSemanticColorGroup(
        accent: AppColors.inkSoft,
        container: AppColors.paperMuted,
        onContainer: AppColors.ink,
      ),
    );
  });

  test('kontras minimum terpenuhi', () {
    expect(
      contrastRatio(AppColors.ink, AppColors.paperBright),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.inkSoft, AppColors.paperBright),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.siswaOnContainer, AppColors.siswaContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.guruOnContainer, AppColors.guruContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.waliOnContainer, AppColors.waliContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.adminOnContainer, AppColors.adminContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.successOnContainer, AppColors.successContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.warningOnContainer, AppColors.warningContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.errorOnContainer, AppColors.errorContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.infoOnContainer, AppColors.infoContainer),
      greaterThanOrEqualTo(4.5),
    );
  });
}
