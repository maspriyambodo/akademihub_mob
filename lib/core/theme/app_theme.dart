import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF087F8C);
  static const Color primaryLight = Color(0xFF18D5C4);
  static const Color primaryDark = Color(0xFF061A2C);
  static const Color secondary = Color(0xFFFFC857);
  static const Color accent = Color(0xFF7479FF);

  // Role accent colors
  static const Color siswaColor = Color(0xFF00AFC1);
  static const Color guruColor = Color(0xFF5965D8);
  static const Color waliColor = Color(0xFFD88918);
  static const Color adminColor = Color(0xFFD94B65);

  // Semantic colors
  static const Color success = Color(0xFF2E7D4F);
  static const Color warning = Color(0xFFB66A12);
  static const Color error = Color(0xFFBA3D46);
  static const Color info = Color(0xFF287CA8);

  // Neutral
  static const Color surface = Color(0xFFF4F7FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFDDE8EE);
  static const Color textPrimary = Color(0xFF102638);
  static const Color textSecondary = Color(0xFF566B78);
  static const Color textHint = Color(0xFF8295A0);
  static const Color surfaceMuted = Color(0xFFE8F2F5);
}

class AppTheme {
  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD7F8F4),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.cardBg,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      outline: AppColors.divider,
      outlineVariant: Color(0xFFDDE8EE),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xF7F4F7FA),
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xF7FFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: const Color(0x18061A2C),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x99DDE8EE)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shadowColor: AppColors.primaryDark.withAlpha(50),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.divider),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          focusColor: Color(0xFFD7F8F4),
          highlightColor: Color(0xFFD7F8F4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xEFFFFFFF),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          height: 1.05,
        ),
        headlineSmall: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 26,
          letterSpacing: -0.7,
          height: 1.12,
        ),
        titleLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 21,
          letterSpacing: -0.35,
        ),
        titleMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: const TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.cardBg,
        selectedColor: const Color(0xFFD7F8F4),
        side: const BorderSide(color: AppColors.divider),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      tabBarTheme: const TabBarThemeData(
        dividerColor: AppColors.divider,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 1,
        focusElevation: 2,
        hoverElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: const Color(0xFA061A2C),
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x3318D5C4),
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryLight
                : const Color(0xFF91A8B6),
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFF91A8B6),
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.primaryDark,
        indicatorColor: Color(0x3318D5C4),
        selectedIconTheme: IconThemeData(color: AppColors.primaryLight),
        unselectedIconTheme: IconThemeData(color: Color(0xFF91A8B6)),
        selectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: Color(0xFF91A8B6)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceMuted,
        circularTrackColor: AppColors.surfaceMuted,
      ),
      extensions: const <ThemeExtension<dynamic>>[AppDataTypography()],
    );
  }

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}

@immutable
class AppDataTypography extends ThemeExtension<AppDataTypography> {
  const AppDataTypography();

  TextStyle get value => const TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  AppDataTypography copyWith() => this;

  @override
  AppDataTypography lerp(AppDataTypography? other, double t) => this;
}
