import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF00ACC1);
  static const Color accent = Color(0xFF26A69A);

  // Role accent colors
  static const Color siswaColor = Color(0xFF42A5F5);
  static const Color guruColor = Color(0xFF66BB6A);
  static const Color waliColor = Color(0xFFFF7043);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral
  static const Color surface = Color(0xFFF5F7FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      labelSmall: TextStyle(color: AppColors.textHint, fontSize: 11),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}
