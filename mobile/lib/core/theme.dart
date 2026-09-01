import 'package:flutter/material.dart';

/// Modern color palette for Energy Eniwhere
class AppColors {
  // Primary - Electric Blue to Teal gradient
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color primaryTeal = Color(0xFF00D9C0);

  // Accent colors
  static const Color accentPurple = Color(0xFF7B61FF);
  static const Color accentOrange = Color(0xFFFF6B35);

  // Status colors
  static const Color successGreen = Color(0xFF00C48C);
  static const Color warningYellow = Color(0xFFFFB800);
  static const Color errorRed = Color(0xFFFF3B30);

  // Neutrals
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1C1C1E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2C2E);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF3A3A3C);
  /// Use on dark surfaces only — never black or mid-gray.
  static const Color textOnDark = Color(0xFFF5F5F7);
  static const Color textOnDarkSecondary = Color(0xFFD1D1D6);
  static const Color divider = Color(0xFFE5E5EA);

  /// Secondary labels: never black/dark-gray on a dark surface.
  static Color secondaryLabel(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textOnDarkSecondary
        : textSecondary;
  }

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentPurple, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// App theme configuration
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      secondary: AppColors.primaryTeal,
      tertiary: AppColors.accentPurple,
      surface: AppColors.backgroundLight,
      background: AppColors.backgroundLight,
      error: AppColors.errorRed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
      labelStyle: const TextStyle(
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryTeal,
      secondary: AppColors.accentPurple,
      tertiary: AppColors.primaryBlue,
      surface: AppColors.cardDark,
      error: AppColors.errorRed,
      onPrimary: Color(0xFF111111),
      onSecondary: AppColors.textOnDark,
      onSurface: AppColors.textOnDark,
      onError: AppColors.textOnDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textOnDark,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textOnDark,
      ),
      iconTheme: IconThemeData(color: AppColors.textOnDark),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textOnDark),
      bodyMedium: TextStyle(color: AppColors.textOnDark),
      bodySmall: TextStyle(color: AppColors.textOnDarkSecondary),
      titleLarge: TextStyle(color: AppColors.textOnDark),
      titleMedium: TextStyle(color: AppColors.textOnDark),
      titleSmall: TextStyle(color: AppColors.textOnDark),
      headlineSmall: TextStyle(color: AppColors.textOnDark),
      labelLarge: TextStyle(color: AppColors.textOnDark),
    ),
    iconTheme: const IconThemeData(color: AppColors.textOnDark),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
        backgroundColor: AppColors.primaryTeal,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textOnDark,
        side: const BorderSide(color: AppColors.textOnDarkSecondary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      hintStyle: const TextStyle(color: AppColors.textOnDarkSecondary),
      labelStyle: const TextStyle(color: AppColors.textOnDark),
      prefixIconColor: AppColors.textOnDark,
      suffixIconColor: AppColors.textOnDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF636366)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: Color(0xFF111111),
    ),
  );
}
