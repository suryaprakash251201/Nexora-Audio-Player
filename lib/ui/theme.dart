import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF06060A);
  static const Color surface = Color(0xFF0B0B12);
  static const Color surfaceRaised = Color(0xFF1A1A24);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color textDim = Color(0xFF71717A);
  static const Color border = Color(0xFF27272A);
  static const Color hairline = Color(0xFF3F3F46);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.soraTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.secondary,
        inactiveTrackColor: AppColors.surfaceRaised,
        thumbColor: Colors.white,
        overlayColor: AppColors.secondary.withOpacity(0.2),
        trackHeight: 4,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
