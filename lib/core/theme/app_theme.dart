import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
        titleLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Quicksand', color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.dark,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
        titleLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Quicksand', color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
