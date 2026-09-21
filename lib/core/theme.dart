import 'package:flutter/material.dart';

class AppColors {
  static const black = Color(0xFF000000);
  static const ink = Color(0xFF111827);
  static const slate900 = Color(0xFF0F172A);
  static const slate700 = Color(0xFF334155);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50 = Color(0xFFF8FAFC);
  static const page = Color(0xFFF4F4F6);
  static const rose = Color(0xFFE11D48);
  static const roseSoft = Color(0xFFFFF1F2);
  static const amber = Color(0xFFF59E0B);
  static const emerald = Color(0xFF059669);
  static const white = Color(0xFFFFFFFF);
}

ThemeData buildTakhfidTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.slate50,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.black,
      secondary: AppColors.rose,
      surface: AppColors.white,
      error: AppColors.rose,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.slate200, width: 1),
      ),
      color: AppColors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.rose,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.slate100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.black, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.rose),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(
        color: AppColors.slate400,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodySmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.slate500,
      ),
      labelLarge: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.ink,
      size: 20,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.slate200,
      thickness: 1,
      space: 1,
    ),
  );
}
