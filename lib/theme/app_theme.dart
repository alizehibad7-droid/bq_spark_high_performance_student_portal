// File: lib/theme/app_theme.dart
// All Bano Qabil brand colors — never hardcode colors in screens

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary    = Color(0xFF1A5C35); // Dark Green
  static const Color secondary  = Color(0xFFB8A030); // Golden
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color cardColor  = Color(0xFFF0F7F2); // Light green card
  static const Color textDark   = Color(0xFF1A5C35); // Green text
  static const Color textLight  = Color(0xFFFFFFFF); // White text
  static const Color textGray   = Color(0xFF6B7280); // Muted gray
  static const Color divider    = Color(0xFFE5E7EB); // Divider
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.cardColor,
        labelStyle: const TextStyle(color: AppColors.textGray),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }
}