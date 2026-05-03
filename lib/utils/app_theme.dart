import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StudyFlow design system — light theme, accessibility-first.
/// Spec colours: Background #F8F8F6, Surface #FFFFFF, Primary text #1A2340,
/// Secondary #6B7A99, Accent #00B4A6, Error #E05252, Success #3DB87A
class AppColors {
  static const background = Color(0xFFF8F8F6);
  static const surface    = Color(0xFFFFFFFF);
  static const primary    = Color(0xFF1A2340); // navy
  static const secondary  = Color(0xFF6B7A99);
  static const accent     = Color(0xFF00B4A6); // teal
  static const accentLight = Color(0xFFE0F7F5);
  static const error      = Color(0xFFE05252);
  static const success    = Color(0xFF3DB87A);
  static const border     = Color(0xFFE5EAF0);
  static const muted      = Color(0xFF9BAABF);

  // Gamification
  static const xpGold     = Color(0xFFF59E0B);
  static const streakOrange = Color(0xFFEF6C00);
}

class AppTheme {
  // Keep legacy aliases so existing files that import app_theme.dart still compile
  static const Color bgColor      = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color navyText     = AppColors.primary;
  static const Color greyText     = AppColors.secondary;
  static const Color mutedText    = AppColors.muted;
  static const Color borderColor  = AppColors.border;
  static const Color accent       = AppColors.accent;
  static const Color accentLight  = AppColors.accentLight;
  static const Color errorColor   = AppColors.error;
  static const Color drawerBg     = AppColors.primary;
  static const Color primaryPurple = AppColors.accent;
  static const Color electricBlue  = AppColors.accent;
  static const Color cyan          = AppColors.accent;

  static ThemeData get lightTheme {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorSchemeSeed: AppColors.accent,
      textTheme: base.apply(
        bodyColor: AppColors.primary,
        displayColor: AppColors.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(
            color: AppColors.muted, fontWeight: FontWeight.w400),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.accent),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.muted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Backward-compat alias
  static ThemeData get darkTheme => lightTheme;
}
