import 'package:flutter/material.dart';

/// Design tokens for Ruang Belajar Nusantara.
enum AppStatusTone { success, warning, error, info, neutral }

class AppRoleColorGroup {
  final Color accent;
  final Color container;
  final Color onContainer;

  const AppRoleColorGroup({
    required this.accent,
    required this.container,
    required this.onContainer,
  });
}

class AppSemanticColorGroup {
  final Color accent;
  final Color container;
  final Color onContainer;

  const AppSemanticColorGroup({
    required this.accent,
    required this.container,
    required this.onContainer,
  });
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class AppColors {
  static const Color ink = Color(0xFF0F172A);
  static const Color textPrimary = ink;
  static const Color inkSoft = Color(0xFF334155);
  static const Color textSecondary = inkSoft;
  static const Color inkMuted = Color(0xFF64748B);
  static const Color textHint = inkMuted;
  static const Color paper = Color(0xFFF8FAFC);
  static const Color surface = paper;
  static const Color paperBright = Color(0xFFFFFFFF);
  static const Color cardBg = paperBright;
  static const Color paperMuted = Color(0xFFF1F5F9);
  static const Color surfaceMuted = paperMuted;
  static const Color line = Color(0xFFE2E8F0);
  static const Color divider = line;
  static const Color primary = Color(0xFF0284C7);
  static const Color primaryDark = Color(0xFF0B192C);
  static const Color primaryLight = Color(0xFFE0F2FE);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color accent = Color(0xFF6366F1);

  static const Color siswaAccent = Color(0xFF0284C7);
  static const Color siswaContainer = Color(0xFFE0F2FE);
  static const Color siswaOnContainer = Color(0xFF075985);
  static const Color siswaColor = siswaAccent;
  static const Color guruAccent = Color(0xFF6366F1);
  static const Color guruContainer = Color(0xFFEEF2FF);
  static const Color guruOnContainer = Color(0xFF3730A3);
  static const Color guruColor = guruAccent;
  static const Color waliAccent = Color(0xFFD97706);
  static const Color waliContainer = Color(0xFFFEF3C7);
  static const Color waliOnContainer = Color(0xFF92400E);
  static const Color waliColor = waliAccent;
  static const Color adminAccent = Color(0xFFE11D48);
  static const Color adminContainer = Color(0xFFFFE4E6);
  static const Color adminOnContainer = Color(0xFF9F1239);
  static const Color adminColor = adminAccent;

  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color successOnContainer = Color(0xFF065F46);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color warningOnContainer = Color(0xFF92400E);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color errorOnContainer = Color(0xFF991B1B);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color infoOnContainer = Color(0xFF1E40AF);

  static AppRoleColorGroup role(String? roleName) =>
      switch (roleName?.toLowerCase().trim()) {
        'siswa' => const AppRoleColorGroup(
          accent: siswaAccent,
          container: siswaContainer,
          onContainer: siswaOnContainer,
        ),
        'guru' => const AppRoleColorGroup(
          accent: guruAccent,
          container: guruContainer,
          onContainer: guruOnContainer,
        ),
        'wali' || 'orang_tua' || 'orangtua' => const AppRoleColorGroup(
          accent: waliAccent,
          container: waliContainer,
          onContainer: waliOnContainer,
        ),
        'admin' || 'superadmin' || 'staff' => const AppRoleColorGroup(
          accent: adminAccent,
          container: adminContainer,
          onContainer: adminOnContainer,
        ),
        _ => const AppRoleColorGroup(
          accent: primary,
          container: primaryLight,
          onContainer: primaryDark,
        ),
      };

  static AppSemanticColorGroup semantic(AppStatusTone tone) => switch (tone) {
    AppStatusTone.success => const AppSemanticColorGroup(
      accent: success,
      container: successContainer,
      onContainer: successOnContainer,
    ),
    AppStatusTone.warning => const AppSemanticColorGroup(
      accent: warning,
      container: warningContainer,
      onContainer: warningOnContainer,
    ),
    AppStatusTone.error => const AppSemanticColorGroup(
      accent: error,
      container: errorContainer,
      onContainer: errorOnContainer,
    ),
    AppStatusTone.info => const AppSemanticColorGroup(
      accent: info,
      container: infoContainer,
      onContainer: infoOnContainer,
    ),
    AppStatusTone.neutral => const AppSemanticColorGroup(
      accent: inkSoft,
      container: paperMuted,
      onContainer: ink,
    ),
  };
}

abstract final class AppElevation {
  static const List<BoxShadow> level0 = [];
  // ponytail: Multi-layered soft ambient shadows; switch to platform shadow shaders when Impeller performance profiles allow.
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x0A102A43),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0E102A43),
      offset: Offset(0, 6),
      blurRadius: 18,
      spreadRadius: -2,
    ),
  ];
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x0D102A43),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x18102A43),
      offset: Offset(0, 16),
      blurRadius: 32,
      spreadRadius: -4,
    ),
  ];
}

abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDark, AppColors.primary],
  );

  static LinearGradient roleHero(Color roleAccent) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryDark,
      Color.alphaBlend(roleAccent.withValues(alpha: 0.7), AppColors.primaryDark),
    ],
  );

  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, AppColors.paperBright],
  );

  static LinearGradient badgeGlow(Color base) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [base.withValues(alpha: 0.18), base.withValues(alpha: 0.08)],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.paperBright,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.paperBright,
      onSurfaceVariant: AppColors.inkSoft,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.errorOnContainer,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xF7F7F5EF),
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          height: 26 / 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paperBright,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: Color(0x8CD8E2E1)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.inkMuted,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.inkMuted,
          minimumSize: const Size(48, 52),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperBright,
        labelStyle: const TextStyle(color: AppColors.inkSoft),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: AppColors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          color: AppColors.ink,
          fontSize: 28,
          height: 34 / 28,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: const TextStyle(
          color: AppColors.ink,
          fontSize: 24,
          height: 30 / 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          height: 26 / 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          height: 22 / 16,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.inkSoft,
          fontSize: 14,
          height: 21 / 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: const TextStyle(
          color: AppColors.inkSoft,
          fontSize: 12,
          height: 18 / 12,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w700,
        ),
        labelSmall: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 11,
          height: 14 / 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.paperMuted,
        selectedColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.inkMuted,
            size: 20,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.inkMuted,
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.primaryDark,
        indicatorColor: AppColors.primaryLight,
        selectedIconTheme: IconThemeData(color: AppColors.primaryDark),
        unselectedIconTheme: IconThemeData(color: AppColors.paperMuted),
        selectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: AppColors.paperMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.paperMuted,
        circularTrackColor: AppColors.paperMuted,
      ),
      extensions: const <ThemeExtension<dynamic>>[AppDataTypography()],
    );
  }

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.primaryDark,
    ),
  );
}

@immutable
class AppDataTypography extends ThemeExtension<AppDataTypography> {
  const AppDataTypography();
  TextStyle get value => const TextStyle(
    color: AppColors.ink,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  @override
  AppDataTypography copyWith() => this;
  @override
  AppDataTypography lerp(AppDataTypography? other, double t) => this;
}
