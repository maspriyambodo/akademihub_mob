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
  static const Color ink = Color(0xFF102A43);
  static const Color textPrimary = ink;
  static const Color inkSoft = Color(0xFF334E68);
  static const Color textSecondary = inkSoft;
  static const Color inkMuted = Color(0xFF526D82);
  static const Color textHint = inkMuted;
  static const Color paper = Color(0xFFF7F5EF);
  static const Color surface = paper;
  static const Color paperBright = Color(0xFFFFFDF8);
  static const Color cardBg = paperBright;
  static const Color paperMuted = Color(0xFFEDF3F2);
  static const Color surfaceMuted = paperMuted;
  static const Color line = Color(0xFFD8E2E1);
  static const Color divider = line;
  static const Color primary = Color(0xFF087F75);
  static const Color primaryDark = Color(0xFF123B46);
  static const Color primaryLight = Color(0xFFBFE8DF);
  static const Color secondary = Color(0xFFE9A23B);
  static const Color accent = Color(0xFF3F67B1);

  static const Color siswaAccent = Color(0xFF168AAD);
  static const Color siswaContainer = Color(0xFFDDF3F8);
  static const Color siswaOnContainer = Color(0xFF0B5065);
  static const Color siswaColor = siswaAccent;
  static const Color guruAccent = Color(0xFF4F63A8);
  static const Color guruContainer = Color(0xFFE7EAF7);
  static const Color guruOnContainer = Color(0xFF293665);
  static const Color guruColor = guruAccent;
  static const Color waliAccent = Color(0xFFC47A16);
  static const Color waliContainer = Color(0xFFF9EBCF);
  static const Color waliOnContainer = Color(0xFF70430B);
  static const Color waliColor = waliAccent;
  static const Color adminAccent = Color(0xFFB94B5F);
  static const Color adminContainer = Color(0xFFF8E2E7);
  static const Color adminOnContainer = Color(0xFF702638);
  static const Color adminColor = adminAccent;

  static const Color success = Color(0xFF2F7D4A);
  static const Color successContainer = Color(0xFFDFF3E5);
  static const Color successOnContainer = Color(0xFF174A2B);
  static const Color warning = Color(0xFFA85F08);
  static const Color warningContainer = Color(0xFFFCEACB);
  static const Color warningOnContainer = Color(0xFF653604);
  static const Color error = Color(0xFFB43C46);
  static const Color errorContainer = Color(0xFFF8DFE1);
  static const Color errorOnContainer = Color(0xFF6E2027);
  static const Color info = Color(0xFF276C99);
  static const Color infoContainer = Color(0xFFDDEEF7);
  static const Color infoOnContainer = Color(0xFF15445F);

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
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x0F102A43), offset: Offset(0, 4), blurRadius: 14),
  ];
  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x1A102A43), offset: Offset(0, 10), blurRadius: 28),
  ];
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
        height: 72,
        elevation: 0,
        backgroundColor: AppColors.paperBright,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryDark,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.inkMuted,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.inkMuted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
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
